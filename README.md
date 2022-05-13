# ExAws.SNS

[![Module Version](https://img.shields.io/hexpm/v/ex_aws_sns.svg)](https://hex.pm/packages/ex_aws_sns)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ex_aws_sns/)
[![Total Download](https://img.shields.io/hexpm/dt/ex_aws_sns.svg)](https://hex.pm/packages/ex_aws_sns)
[![License](https://img.shields.io/hexpm/l/ex_aws_sns.svg)](https://github.com/ex-aws/ex_aws_sns/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/ex-aws/ex_aws_sns.svg)](https://github.com/ex-aws/ex_aws_sns/commits/master)

Service module for https://github.com/ex-aws/ex_aws

## Installation

The package can be installed by adding `:ex_aws_sns` to your list of dependencies in `mix.exs`
along with `:ex_aws` and your preferred JSON codec / HTTP client:

```elixir
def deps do
  [
    {:ex_aws, "~> 2.0"},
    {:ex_aws_sns, "~> 2.0"},
    {:poison, "~> 3.0"},
    {:hackney, "~> 1.9"},
  ]
end
```

## Usage

### Publishing a message

Here is an example of sending a message to a standard topic and returning the response to the caller

```elixir
    message
    |> ExAws.SNS.publish(
      topic_arn: "arn:aws:sns:us-east-1:000000000000:sns-topic-name"
    )
    |> ExAws.request()
    |> case do
      {:error, {_error_type, error_code, %{code: message}}} ->
        {:error, "Response returned with http error code #{error_code} and message #{message}"}
      {:error, {_error_type, error_code, message}} ->
        {:error, "Response returned with http error code #{error_code} and message #{message}"}
      response -> response
    end
```

The following code demonstrates sending a message to a FIFO topic. [message_group_id](https://docs.aws.amazon.com/sns/latest/dg/fifo-message-grouping.html) defines partitions in
the topic to make sure messages in that group are processed one at a time. If all messages must be processed in order
use a static value for this attribute. [message_deduplication_id](https://docs.aws.amazon.com/sns/latest/dg/fifo-message-dedup.html) defines an id used to determine if two events are the same
and deduplicate them in the topic. Event IDs or hashes of the content are good for this.

```elixir
    message
    |> ExAws.SNS.publish(
      topic_arn: "arn:aws:sns:us-east-1:000000000000:sns-topic-name.fifo",
      message_group_id: "some group which requires messages processed in order",
      message_deduplication_id: "some id to prevent the same message from being published twice"
    )
    |> ExAws.request()
    |> case do
      {:error, {_error_type, error_code, %{code: message}}} ->
        {:error, "Response returned with http error code #{error_code} and message #{message}"}
      {:error, {_error_type, error_code, message}} ->
        {:error, "Response returned with http error code #{error_code} and message #{message}"}
      response -> response
    end
```

## Copyright and License

The MIT License (MIT)

Copyright (c) 2017 CargoSense, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
