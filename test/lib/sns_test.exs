defmodule ExAws.SNSTest do
  use ExUnit.Case, async: true
  alias ExAws.SNS

  test "#list_topics" do
    expected = %{"Action" => "ListTopics"}
    assert expected == SNS.list_topics().params
  end

  test "create_topic/1" do
    expected = %{"Action" => "CreateTopic", "Name" => "test_topic"}
    assert expected == SNS.create_topic("test_topic").params
  end

  test "create_topic/2" do
    expected = %{
      "Action" => "CreateTopic",
      "Name" => "test_topic.fifo",
      "Attributes.entry.1.key" => "FifoTopic",
      "Attributes.entry.1.value" => true
    }

    assert expected == SNS.create_topic("test_topic.fifo", [{:fifo_topic, true}]).params
  end

  test "#get_topic_attributes" do
    expected = %{
      "Action" => "GetTopicAttributes",
      "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic"
    }

    assert expected ==
             SNS.get_topic_attributes("arn:aws:sns:us-east-1:982071696186:test-topic").params
  end

  test "#set_topic_attributes" do
    expected = %{
      "Action" => "SetTopicAttributes",
      "AttributeName" => "DeliverPolicy",
      "AttributeValue" => "{\"http\":{\"defaultHealthyRetryPolicy\":{\"numRetries\":5}}}",
      "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic"
    }

    assert expected ==
             SNS.set_topic_attributes(
               :deliver_policy,
               "{\"http\":{\"defaultHealthyRetryPolicy\":{\"numRetries\":5}}}",
               "arn:aws:sns:us-east-1:982071696186:test-topic"
             ).params
  end

  test "#delete_topic" do
    expected = %{
      "Action" => "DeleteTopic",
      "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic"
    }

    assert expected == SNS.delete_topic("arn:aws:sns:us-east-1:982071696186:test-topic").params
  end

  test "#create_platform_application" do
    expected = %{
      "Action" => "CreatePlatformApplication",
      "Name" => "ApplicationName",
      "Platform" => "APNS",
      "Attributes.entry.1.key" => "PlatformCredential",
      "Attributes.entry.1.value" => "foo"
    }

    assert expected ==
             SNS.create_platform_application("ApplicationName", "APNS", %{
               "PlatformCredential" => "foo"
             }).params
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

    assert expected ==
             SNS.create_platform_endpoint(
               "arn:aws:sns:us-west-1:00000000000:app/APNS/test-arn",
               "123abc456def",
               "user data"
             ).params
  end

  test "#create_platform_endpoint removes user data if it's nil" do
    expected = %{
      "Action" => "CreatePlatformEndpoint",
      "PlatformApplicationArn" => "arn:aws:sns:us-west-1:00000000000:app/APNS/test-arn",
      "Token" => "123abc456def"
    }

    assert expected ==
             SNS.create_platform_endpoint(
               "arn:aws:sns:us-west-1:00000000000:app/APNS/test-arn",
               "123abc456def",
               nil
             ).params
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

    assert expected ==
             SNS.get_platform_application_attributes(
               "arn:aws:sns:us-west-1:00000000000:app/APNS/test-arn"
             ).params
  end

  test "#publish_json" do
    expected = %{
      "Action" => "Publish",
      "Message" => "{\"message\": \"MyMessage\"}",
      "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic"
    }

    assert expected ==
             SNS.publish("{\"message\": \"MyMessage\"}",
               topic_arn: "arn:aws:sns:us-east-1:982071696186:test-topic"
             ).params
  end

  test "#publish with message attributes" do
    expected = %{
      "Action" => "Publish",
      "Message" => "Hello World",
      "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic",
      "MessageAttributes.entry.1.Name" => "SenderID",
      "MessageAttributes.entry.1.Value.DataType" => "String",
      "MessageAttributes.entry.1.Value.StringValue" => "sender"
    }

    attrs = [
      %{
        name: "SenderID",
        data_type: :string,
        value: {:string, "sender"}
      }
    ]

    assert expected ==
             SNS.publish("Hello World",
               topic_arn: "arn:aws:sns:us-east-1:982071696186:test-topic",
               message_attributes: attrs
             ).params
  end

  test "#publish with string array message attributes" do
    expected = %{
      "Action" => "Publish",
      "Message" => "Hello World",
      "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic",
      "MessageAttributes.entry.1.Name" => "SenderIDs",
      "MessageAttributes.entry.1.Value.DataType" => "String.Array",
      "MessageAttributes.entry.1.Value.StringValue" => "[\"sender1\",\"sender2\"]"
    }

    attrs = [
      %{
        name: "SenderIDs",
        data_type: :string_array,
        value: {:string_array, ["sender1", "sender2"]}
      }
    ]

    assert expected ==
             SNS.publish("Hello World",
               topic_arn: "arn:aws:sns:us-east-1:982071696186:test-topic",
               message_attributes: attrs
             ).params
  end

  test "#publish FIFO message" do
    expected = %{
      "Action" => "Publish",
      "Message" => "Hello World",
      "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic",
      "MessageDeduplicationId" => "dedupe-id",
      "MessageGroupId" => "group-id"
    }

    assert expected ==
             SNS.publish("Hello World",
               topic_arn: "arn:aws:sns:us-east-1:982071696186:test-topic",
               message_group_id: "group-id",
               message_deduplication_id: "dedupe-id"
             ).params
  end

  test "#publish_batch with string array message attributes" do
    expected = %{
      "Action" => "PublishBatch",
      "PublishBatchRequestEntries.member.1.Id" => 1,
      "PublishBatchRequestEntries.member.1.Message" => "Hello World Message 1",
      "PublishBatchRequestEntries.member.1.MessageAttributes.entry.1.Name" => "SenderIDs",
      "PublishBatchRequestEntries.member.1.MessageAttributes.entry.1.Value.DataType" =>
        "String.Array",
      "PublishBatchRequestEntries.member.1.MessageAttributes.entry.1.Value.StringValue" =>
        "[\"sender1\",\"sender2\"]",
      "PublishBatchRequestEntries.member.1.MessageDeduplicationId" => "dedupe-id1",
      "PublishBatchRequestEntries.member.1.MessageGroupId" => "group-id",
      "PublishBatchRequestEntries.member.2.Id" => 2,
      "PublishBatchRequestEntries.member.2.Message" => "Hello World Message 2",
      "PublishBatchRequestEntries.member.2.MessageAttributes.entry.1.Name" => "SenderIDs",
      "PublishBatchRequestEntries.member.2.MessageAttributes.entry.1.Value.DataType" =>
        "String.Array",
      "PublishBatchRequestEntries.member.2.MessageAttributes.entry.1.Value.StringValue" =>
        "[\"sender1\",\"sender2\"]",
      "PublishBatchRequestEntries.member.2.MessageDeduplicationId" => "dedupe-id2",
      "PublishBatchRequestEntries.member.2.MessageGroupId" => "group-id",
      "PublishBatchRequestEntries.member.3.Id" => 3,
      "PublishBatchRequestEntries.member.3.Message" => "Hello World Message 3",
      "PublishBatchRequestEntries.member.3.MessageAttributes.entry.1.Name" => "SenderIDs",
      "PublishBatchRequestEntries.member.3.MessageAttributes.entry.1.Value.DataType" =>
        "String.Array",
      "PublishBatchRequestEntries.member.3.MessageAttributes.entry.1.Value.StringValue" =>
        "[\"sender1\",\"sender2\"]",
      "PublishBatchRequestEntries.member.3.MessageDeduplicationId" => "dedupe-id3",
      "PublishBatchRequestEntries.member.3.MessageGroupId" => "group-id",
      "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic"
    }

    attrs = [
      %{
        name: "SenderIDs",
        data_type: :string_array,
        value: {:string_array, ["sender1", "sender2"]}
      }
    ]

    assert expected ==
             SNS.publish_batch(
               [
                 %{
                   id: 1,
                   message: "Hello World Message 1",
                   message_attributes: attrs,
                   message_group_id: "group-id",
                   message_deduplication_id: "dedupe-id1"
                 },
                 %{
                   id: 2,
                   message: "Hello World Message 2",
                   message_attributes: attrs,
                   message_group_id: "group-id",
                   message_deduplication_id: "dedupe-id2"
                 },
                 %{
                   id: 3,
                   message: "Hello World Message 3",
                   message_attributes: attrs,
                   message_group_id: "group-id",
                   message_deduplication_id: "dedupe-id3"
                 }
               ],
               "arn:aws:sns:us-east-1:982071696186:test-topic"
             ).params
  end

  test "#subscribe" do
    expected = %{
      "Action" => "Subscribe",
      "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic",
      "Protocol" => "https",
      "Endpoint" => "https://example.com",
      "ReturnSubscriptionArn" => false
    }

    assert expected ==
             SNS.subscribe(
               "arn:aws:sns:us-east-1:982071696186:test-topic",
               "https",
               "https://example.com"
             ).params
  end

  test "#subscribe with return_subscription_arn" do
    expected = %{
      "Action" => "Subscribe",
      "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic",
      "Protocol" => "https",
      "Endpoint" => "https://example.com",
      "ReturnSubscriptionArn" => true
    }

    opts = [return_subscription_arn: true]

    assert expected ==
             SNS.subscribe(
               "arn:aws:sns:us-east-1:982071696186:test-topic",
               "https",
               "https://example.com",
               opts
             ).params
  end

  test "#confirm_subscription" do
    expected = %{
      "Action" => "ConfirmSubscription",
      "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic",
      "Token" => "topic_token",
      "AuthenticateOnUnsubscribe" => "true"
    }

    assert expected ==
             SNS.confirm_subscription(
               "arn:aws:sns:us-east-1:982071696186:test-topic",
               "topic_token",
               true
             ).params
  end

  test "#list_subscriptions" do
    expected = %{"Action" => "ListSubscriptions"}
    assert expected == SNS.list_subscriptions().params

    expected = %{"Action" => "ListSubscriptions", "NextToken" => "123456789"}
    assert expected == SNS.list_subscriptions("123456789").params
  end

  test "#list_subscriptions_by_topic" do
    expected = %{
      "Action" => "ListSubscriptionsByTopic",
      "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic"
    }

    assert expected ==
             SNS.list_subscriptions_by_topic("arn:aws:sns:us-east-1:982071696186:test-topic").params

    expected = %{
      "Action" => "ListSubscriptionsByTopic",
      "TopicArn" => "arn:aws:sns:us-east-1:982071696186:test-topic",
      "NextToken" => "123456789"
    }

    assert expected ==
             SNS.list_subscriptions_by_topic("arn:aws:sns:us-east-1:982071696186:test-topic",
               next_token: "123456789"
             ).params
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
      "AttributeValue" => "{\"healthyRetryPolicy\":{\"numRetries\":5}}"
    }

    assert expected ==
             SNS.set_subscription_attributes(
               :delivery_policy,
               "{\"healthyRetryPolicy\":{\"numRetries\":5}}",
               subscription_arn
             ).params

    expected = %{
      "Action" => "SetSubscriptionAttributes",
      "SubscriptionArn" => subscription_arn,
      "AttributeName" => "RawMessageDelivery",
      "AttributeValue" => "{\"healthyRetryPolicy\":{\"numRetries\":5}}"
    }

    assert expected ==
             SNS.set_subscription_attributes(
               :raw_message_delivery,
               "{\"healthyRetryPolicy\":{\"numRetries\":5}}",
               subscription_arn
             ).params

    expected = %{
      "Action" => "SetSubscriptionAttributes",
      "SubscriptionArn" => subscription_arn,
      "AttributeName" => "FilterPolicy",
      "AttributeValue" => "{\"status\":[\"ok\"]}"
    }

    assert expected ==
             SNS.set_subscription_attributes(
               :filter_policy,
               "{\"status\":[\"ok\"]}",
               subscription_arn
             ).params
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

  test "#check_if_phone_number_is_opted_out" do
    expected = %{"Action" => "CheckIfPhoneNumberIsOptedOut", "phoneNumber" => "+15005550006"}
    assert expected == SNS.check_if_phone_number_is_opted_out("+15005550006").params
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
      "Attributes.entry.1.key" => "Token",
      "Attributes.entry.1.value" => "1234",
      "Attributes.entry.2.key" => "Enabled",
      "Attributes.entry.2.value" => false,
      "Attributes.entry.3.key" => "CustomUserData",
      "Attributes.entry.3.value" => "blah",
      "EndpointArn" => "test-endpoint-arn"
    }

    assert expected ==
             SNS.set_endpoint_attributes("test-endpoint-arn",
               token: "1234",
               enabled: false,
               custom_user_data: "blah"
             ).params
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

    assert expected ==
             SNS.list_endpoints_by_platform_application(
               "arn:aws:sns:us-west-1:00000000000:app/APNS/test-arn"
             ).params
  end

  # Requires AWS access
  @tag :skip
  describe "verify_message/1" do
    setup [:add_verify_message]

    test "validate a pristine message from SNS and check that the key is cached", %{
      verify_message: message
    } do
      assert :ok == SNS.verify_message(message)

      url = message["SigningCertURL"]
      assert [{^url, {:RSAPublicKey, _, _}}] = :ets.lookup(ExAws.SNS.PublicKeyCache, url)
    end

    test "fails with tampered message", %{verify_message: message} do
      assert {:error, _message} = SNS.verify_message(message |> Map.put("Message", "message"))
    end

    test "fails with a missing message params", %{verify_message: message} do
      assert {:error, _message} = SNS.verify_message(message |> Map.delete("Timestamp"))
    end

    test "fails with an unsupported signature version", %{verify_message: message} do
      assert {:error, _message} = SNS.verify_message(message |> Map.put("SignatureVersion", "3"))
    end

    test "fails with invalid certificate URL", %{verify_message: message} do
      assert {:error, _message} =
               SNS.verify_message(
                 message
                 |> Map.put("SigningCertURL", "http://example.com/cert.pem")
               )
    end

    test "fails with invalid certificate scheme", %{verify_message: message} do
      assert {:error, _message} =
               SNS.verify_message(
                 message
                 |> Map.put(
                   "SigningCertURL",
                   String.replace(message["SigningCertURL"], "https", "http")
                 )
               )
    end
  end

  defp add_verify_message(context) do
    message = %{
      "Type" => "SubscriptionConfirmation",
      "MessageId" => "72e8378d-e4e4-4a17-b3ef-89baa9c6b615",
      "Token" =>
        "2336412f37fb687f5d51e6e2425929f528fce8aa114aa3c70e8756de60608f0bd9e37d5388ff22d52a04ce89a27efa4104bcc2e8233ff7a9e81294fe7b0cd1df7b23e2133b3bfc7a5ad4d12a0989c8f3c340ef78035d2026701832154651e13f8e8acb64a48f8a6647ffd022a1250648",
      "TopicArn" => "arn:aws:sns:us-east-1:206176965479:ex_aws_test",
      "Message" =>
        "You have chosen to subscribe to the topic arn:aws:sns:us-east-1:206176965479:ex_aws_test.\nTo confirm the subscription, visit the SubscribeURL included in this message.",
      "SubscribeURL" =>
        "https://sns.us-east-1.amazonaws.com/?Action=ConfirmSubscription&TopicArn=arn:aws:sns:us-east-1:206176965479:ex_aws_test&Token=2336412f37fb687f5d51e6e2425929f528fce8aa114aa3c70e8756de60608f0bd9e37d5388ff22d52a04ce89a27efa4104bcc2e8233ff7a9e81294fe7b0cd1df7b23e2133b3bfc7a5ad4d12a0989c8f3c340ef78035d2026701832154651e13f8e8acb64a48f8a6647ffd022a1250648",
      "Timestamp" => "2026-05-20T05:42:47.203Z",
      "SignatureVersion" => "1",
      "Signature" =>
        "Lc5HVdFIcnNny+IpGawrITsugH0m4AfGJUKm8vypd1Mt7Ly/EcnajiUsNa515gj3wBuy/EYXl8EyE+HAsCII7JfKXy8Ho6mt7RFoFP8r+nfBhipTOPipyyQdsFVofQnV3YpM6gx4Cv9LRlE2CCDp4j7wbL1AejNRwuDBXctbNMd/OGMtodOEsyBJ8gFqgPn5LmLEcxwtN07lPx0mO+CTct1cinzoigQo7KXNrklj3iW4L2jTgt8VsxDEAW3/sGaHaujLMeW2kft+3ebGgxBECkoTUkhwqmbXkxIB3c/TAVNvX+svz29Z3zNXoXtB3GOgeEC00/IoftBmISNOcA7B7g==",
      "SigningCertURL" =>
        "https://sns.us-east-1.amazonaws.com/SimpleNotificationService-7506a1e35b36ef5a444dd1a8e7cc3ed8.pem"
    }

    context |> Map.put(:verify_message, message)
  end
end
