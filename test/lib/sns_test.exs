defmodule ExAws.SNSTest do
  use ExUnit.Case, async: true
  alias ExAws.SNS

  test "#list_topics" do
    expected = %{"Action" => "ListTopics"}
    assert expected == SNS.list_topics().params
  end

  test "#create_topic" do
    expected = %{"Action" => "CreateTopic", "Name" => "test_topic"}
    assert expected == SNS.create_topic("test_topic").params
  end

  test "#get_topic_attributes" do
    expected = %{"Action" => "GetTopicAttributes", "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic"}
    assert expected == SNS.get_topic_attributes("arn:aws:sns:us-east-1:982071696186:test-topic").params
  end

  test "#set_topic_attributes" do
    expected = %{
      "Action" => "SetTopicAttributes",
      "AttributeName" => "DeliverPolicy",
      "AttributeValue" => "{\"http\":{\"defaultHealthyRetryPolicy\":{\"numRetries\":5}}}",
      "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic"
    }
    assert expected == SNS.set_topic_attributes(:deliver_policy, "{\"http\":{\"defaultHealthyRetryPolicy\":{\"numRetries\":5}}}", "arn:aws:sns:us-east-1:982071696186:test-topic").params
  end

  test "#delete_topic" do
    expected = %{"Action" => "DeleteTopic", "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic"}
    assert expected == SNS.delete_topic("arn:aws:sns:us-east-1:982071696186:test-topic").params
  end

  test "#create_platform_application" do
    expected = %{
      "Action" => "CreatePlatformApplication",
      "Name" => "ApplicationName",
      "Platform" => "APNS",
      "Attributes.entry.1.key" => "PlatformCredential",
      "Attributes.entry.1.value" => "foo",
    }
    assert expected == SNS.create_platform_application("ApplicationName", "APNS", %{"PlatformCredential" => "foo"}).params
  end

  test "#delete_platform_application" do
    expected = %{
      "Action" => "DeletePlatformApplication",
      "PlatformApplicationArn" => "test-endpoint-arn"
    }
    assert expected == SNS.delete_platform_application("test-endpoint-arn").params
  end

  test "#create_platform_endpoint" do
    expected = %{
      "Action" => "CreatePlatformEndpoint",
      "CustomUserData" => "user data",
      "PlatformApplicationArn" => "arn:aws:sns:us-west-1:00000000000:app/APNS/test-arn",
      "Token" => "123abc456def"
    }
    assert expected == SNS.create_platform_endpoint("arn:aws:sns:us-west-1:00000000000:app/APNS/test-arn", "123abc456def", "user data").params
  end

  test "#create_platform_endpoint removes user data if it's nil" do
    expected = %{
      "Action" => "CreatePlatformEndpoint",
      "PlatformApplicationArn" => "arn:aws:sns:us-west-1:00000000000:app/APNS/test-arn",
      "Token" => "123abc456def"
    }
    assert expected == SNS.create_platform_endpoint("arn:aws:sns:us-west-1:00000000000:app/APNS/test-arn", "123abc456def", nil).params
  end

  test "#list_platform_applications" do
    expected = %{"Action" => "ListPlatformApplications"}
    assert expected == SNS.list_platform_applications().params

    expected = %{"Action" => "ListPlatformApplications", "NextToken" => "123456789"}
    assert expected == SNS.list_platform_applications("123456789").params
  end

  test "#get_platform_application_attributes" do
    expected = %{
      "Action" => "GetPlatformApplicationAttributes",
      "PlatformApplicationArn" => "arn:aws:sns:us-west-1:00000000000:app/APNS/test-arn"
    }
    assert expected == SNS.get_platform_application_attributes("arn:aws:sns:us-west-1:00000000000:app/APNS/test-arn").params
  end

  test "#publish_json" do
    expected = %{
      "Action" => "Publish",
      "Message" => "{\"message\": \"MyMessage\"}",
      "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic"
    }
    assert expected == SNS.publish("{\"message\": \"MyMessage\"}", [topic_arn: "arn:aws:sns:us-east-1:982071696186:test-topic"]).params
  end

  test"#publish with message attributes" do
    expected = %{
      "Action" => "Publish",
      "Message" => "Hello World",
      "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic",
      "MessageAttributes.entry.1.Name" => "SenderID",
      "MessageAttributes.entry.1.Value.DataType" => "String",
      "MessageAttributes.entry.1.Value.StringValue" => "sender"
    }

    attrs = [%{
      name: "SenderID",
      data_type: :string,
      value: {:string, "sender"}
    }]

    assert expected == SNS.publish("Hello World", [topic_arn: "arn:aws:sns:us-east-1:982071696186:test-topic", message_attributes: attrs]).params
  end

  test "#subscribe" do
    expected = %{
      "Action"   => "Subscribe",
      "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic",
      "Protocol" => "https",
      "Endpoint" => "https://example.com",
      "ReturnSubscriptionArn" => false
    }
    assert expected == SNS.subscribe("arn:aws:sns:us-east-1:982071696186:test-topic", "https", "https://example.com").params
  end

  test "#subscribe with return_subscription_arn" do
    expected = %{
      "Action"   => "Subscribe",
      "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic",
      "Protocol" => "https",
      "Endpoint" => "https://example.com",
      "ReturnSubscriptionArn" => true
    }

    opts = [return_subscription_arn: true]
    assert expected == SNS.subscribe("arn:aws:sns:us-east-1:982071696186:test-topic", "https", "https://example.com", opts).params
  end

  test "#confirm_subscription" do
    expected = %{
      "Action"   => "ConfirmSubscription",
      "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic",
      "Token" => "topic_token",
      "AuthenticateOnUnsubscribe" => "true"
    }
    assert expected == SNS.confirm_subscription("arn:aws:sns:us-east-1:982071696186:test-topic", "topic_token", true).params
  end

  test "#list_subscriptions" do
    expected = %{"Action" => "ListSubscriptions"}
    assert expected == SNS.list_subscriptions().params

    expected = %{"Action" => "ListSubscriptions", "NextToken" => "123456789" }
    assert expected == SNS.list_subscriptions("123456789").params
  end

  test "#list_subscriptions_by_topic" do
    expected = %{"Action" => "ListSubscriptionsByTopic", "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic"}
    assert expected == SNS.list_subscriptions_by_topic("arn:aws:sns:us-east-1:982071696186:test-topic").params

    expected = %{"Action" => "ListSubscriptionsByTopic", "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic", "NextToken" => "123456789"}
    assert expected == SNS.list_subscriptions_by_topic("arn:aws:sns:us-east-1:982071696186:test-topic", next_token: "123456789").params
  end

  test "#unsubscribe" do
    subscription_arn = "arn:aws:sns:us-east-1:982071696186:test-topic:subscription123"
    expected = %{
      "Action" => "Unsubscribe",
      "SubscriptionArn" => subscription_arn
    }
    assert expected == SNS.unsubscribe(subscription_arn).params
  end

  test "#get_subscription_attributes" do
    subscription_arn = "arn:aws:sns:us-east-1:982071696186:test-topic:subscription123"
    expected = %{
      "Action" => "GetSubscriptionAttributes",
      "SubscriptionArn" => subscription_arn
    }
    assert expected == SNS.get_subscription_attributes(subscription_arn).params
  end

  test "#set_subscription_attributes" do
    subscription_arn = "arn:aws:sns:us-east-1:982071696186:test-topic:subscription123"
    expected = %{
      "Action" => "SetSubscriptionAttributes",
      "SubscriptionArn" => subscription_arn,
      "AttributeName" => "DeliveryPolicy",
      "AttributeValue" => "{\"healthyRetryPolicy\":{\"numRetries\":5}}",
    }
    assert expected == SNS.set_subscription_attributes(
      :delivery_policy,
      "{\"healthyRetryPolicy\":{\"numRetries\":5}}",
      subscription_arn).params

    expected = %{
      "Action" => "SetSubscriptionAttributes",
      "SubscriptionArn" => subscription_arn,
      "AttributeName" => "RawMessageDelivery",
      "AttributeValue" => "{\"healthyRetryPolicy\":{\"numRetries\":5}}",
    }
    assert expected == SNS.set_subscription_attributes(
      :raw_message_delivery,
      "{\"healthyRetryPolicy\":{\"numRetries\":5}}",
      subscription_arn).params

    expected = %{
      "Action" => "SetSubscriptionAttributes",
      "SubscriptionArn" => subscription_arn,
      "AttributeName" => "FilterPolicy",
      "AttributeValue" => "{\"status\":[\"ok\"]}",
    }
    assert expected == SNS.set_subscription_attributes(
      :filter_policy,
      "{\"status\":[\"ok\"]}",
      subscription_arn).params
  end

  test "#list_phone_numbers_opted_out" do
    expected = %{"Action" => "ListPhoneNumbersOptedOut"}
    assert expected == SNS.list_phone_numbers_opted_out().params

    expected = %{"Action" => "ListPhoneNumbersOptedOut", "nextToken" => "123456789"}
    assert expected == SNS.list_phone_numbers_opted_out("123456789").params
  end

  test "#opt_in_phone_number" do
    expected = %{"Action" => "OptInPhoneNumber", "phoneNumber" => "+15005550006"}
    assert expected == SNS.opt_in_phone_number("+15005550006").params
  end

  # Test SMS request structure. Credentials via (https://www.twilio.com/docs/api/rest/test-credentials).
  test "#publish_sms" do
    expected = %{
      "Action" => "Publish",
      "Message" => "message",
      "MessageAttributes.entry.1.Name" => "AWS.SNS.SMS.SenderID",
      "MessageAttributes.entry.1.Value.DataType" => "String",
      "MessageAttributes.entry.1.Value.StringValue" => "sender",
      "MessageAttributes.entry.2.Name" => "AWS.SNS.SMS.MaxPrice",
      "MessageAttributes.entry.2.Value.DataType" => "String",
      "MessageAttributes.entry.2.Value.StringValue" => "0.8",
      "MessageAttributes.entry.3.Name" => "AWS.SNS.SMS.SMSType",
      "MessageAttributes.entry.3.Value.DataType" => "String",
      "MessageAttributes.entry.3.Value.StringValue" => "Transactional",
      "PhoneNumber" => "+15005550006"
    }

    message_attributes = [
      %{name: "AWS.SNS.SMS.SenderID", data_type: :string, value: {:string, "sender"}},
      %{name: "AWS.SNS.SMS.MaxPrice", data_type: :string, value: {:string, "0.8"}},
      %{name: "AWS.SNS.SMS.SMSType", data_type: :string, value: {:string, "Transactional"}}
    ]
    publish_opts = [
      message_attributes: message_attributes,
      phone_number: "+15005550006"
    ]
    assert expected == SNS.publish("message", publish_opts).params
  end

  test "#get_endpoint_attributes" do
    expected = %{
      "Action" => "GetEndpointAttributes",
      "EndpointArn" => "test-endpoint-arn"
    }
    assert expected == SNS.get_endpoint_attributes("test-endpoint-arn").params
  end

  test "#set_endpoint_attributes" do
    expected = %{
      "Action" => "SetEndpointAttributes",
      "Attributes.entry.1.name" => "Token",
      "Attributes.entry.1.value" => "1234",
      "Attributes.entry.2.name" => "Enabled",
      "Attributes.entry.2.value" => false,
      "Attributes.entry.3.name" => "CustomUserData",
      "Attributes.entry.3.value" => "blah",
      "EndpointArn" => "test-endpoint-arn"
    }
    assert expected == SNS.set_endpoint_attributes("test-endpoint-arn", token: "1234", enabled: false, custom_user_data: "blah").params
  end

  test "#delete_endpoint" do
    expected = %{
      "Action" => "DeleteEndpoint",
      "EndpointArn" => "test-endpoint-arn"
    }
    assert expected == SNS.delete_endpoint("test-endpoint-arn").params
  end

  test "list_endpoints_by_platform_application" do
    expected = %{
      "Action" => "ListEndpointsByPlatformApplication",
      "PlatformApplicationArn" => "arn:aws:sns:us-west-1:00000000000:app/APNS/test-arn"
    }
    assert expected == SNS.list_endpoints_by_platform_application("arn:aws:sns:us-west-1:00000000000:app/APNS/test-arn").params
  end

  describe "verify_message/1" do
    setup [:add_verify_message]

    test "validate a pristine message from SNS", %{verify_message: message} do
      assert :ok == SNS.verify_message(message)
    end

    test "fails with tampered message", %{verify_message: message} do
      assert {:error, _message} = SNS.verify_message(message |> Map.put("Message", "message"))
    end

    test "fails with a missing message params", %{verify_message: message} do
      assert {:error, _message} = SNS.verify_message(message |> Map.delete("Timestamp"))
    end

    test "fails with an invalid signature version", %{verify_message: message} do
      assert {:error, _message} = SNS.verify_message(message |> Map.put("SignatureVersion","2"))
    end
  end

  defp add_verify_message(context) do

    message = %{
      "Type" => "SubscriptionConfirmation",
      "MessageId" => "7a239d1e-aedc-45d6-b81d-ca73cf338784",
      "Token" => "2336412f37fb687f5d51e6e241dbca538bd58e16dbc00d5c1ae1b4c51194942a46bef538907571f4b91b5020c58b5b33d10e6827623c06b0aaa0eb82b3c987bd57ff9819a6ea37e6668e30208d6c23eface7e9998278f6ddac83e4be19a8c1f964316d11d58f7464a417f59a9513a50f",
      "TopicArn" => "arn:aws:sns:us-east-1:668237072717:ex_aws_test",
      "Message" => "You have chosen to subscribe to the topic arn:aws:sns:us-east-1:668237072717:ex_aws_test.\nTo confirm the subscription, visit the SubscribeURL included in this message.",
      "SubscribeURL" => "https://sns.us-east-1.amazonaws.com/?Action=ConfirmSubscription&TopicArn=arn:aws:sns:us-east-1:668237072717:ex_aws_test&Token=2336412f37fb687f5d51e6e241dbca538bd58e16dbc00d5c1ae1b4c51194942a46bef538907571f4b91b5020c58b5b33d10e6827623c06b0aaa0eb82b3c987bd57ff9819a6ea37e6668e30208d6c23eface7e9998278f6ddac83e4be19a8c1f964316d11d58f7464a417f59a9513a50f",
      "Timestamp" => "2019-11-19T16:37:09.068Z",
      "SignatureVersion" => "1",
      "Signature" => "qywQMYSpNetpNnFZXRz7K+lFZ3W7EoyzOzGKJs3aZFAMcJyQDntaNMa2nJhEIoouaiYsu8CwBhelz+iWIvzAudqGDAnVPwVg4XmN3ed0z823oaao2lPP7GocSKN+jKy/cKKXLm1t25d9BaJ9TmY/YF42uG+wGnkBtse3EB3amRPB8U89i2uSHk00Fz5Thx4LI/T4CPWYrb4pdiCHhEWRLUno28h9KQXMFxoDkGBU8clu0GYhJ56ChUwmAQytp3KHsDQrI/Cd65uXUILR3IwskR+z8rGsh5nvCHVkn/3qWTNTLTdbiBO2b+ewPiQFi3LB/wrOutKE63jlampZRk7BcQ==",
      "SigningCertURL" => "https://sns.us-east-1.amazonaws.com/SimpleNotificationService-6aad65c2f9911b05cd53efda11f913f9.pem"
    }
    context |> Map.put(:verify_message, message)
  end

end
