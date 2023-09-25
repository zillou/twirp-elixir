defmodule Twirp.EncoderTest do
  use ExUnit.Case, async: true

  alias Twirp.Encoder
  alias Twirp.Test.Req
  alias Twirp.Test.Envelope
  alias Twirp.Test.BatchReq

  describe "decode/3 with json" do
    test "converts json to protobuf" do
      assert {:ok, %Req{msg: "test"}} = Encoder.decode(%{msg: "test"}, Req, "application/json")
    end

    test "converts nested string fields" do
      assert {:ok, %Envelope{msg: "test", sub: %Req{msg: "test"}}} ==
               Encoder.decode(
                 %{"msg" => "test", "sub" => %{"msg" => "test"}},
                 Envelope,
                 "application/json"
               )
    end

    test "converts nested JSON to nested structs" do
      assert {:ok, %Envelope{sub: %Req{msg: "test"}}} =
               Encoder.decode(%{sub: %{msg: "test"}}, Envelope, "application/json")
    end

    test "converts JSON rith repeated fields to structs" do
      assert {:ok, %BatchReq{requests: [%Req{msg: "test1"}, %Req{msg: "test2"}]}} =
               Encoder.decode(
                 %{requests: [%{msg: "test1"}, %{msg: "test2"}]},
                 BatchReq,
                 "application/json"
               )
    end

    test "converts string keys to atom keys in nested lists fields" do
      response =
        Encoder.decode(
          %{"requests" => [%{"msg" => "test1"}, %{"msg" => "test2"}]},
          BatchReq,
          "application/json"
        )

      assert {:ok, %BatchReq{requests: [%Req{msg: "test1"}, %Req{msg: "test2"}]}} = response
    end
  end

  describe "encode/3 as json " do
    test "encodes to JSON without implementing a JSON protocol" do
      encoded =
        Encoder.encode(
          %Envelope{msg: "test", sub: %Req{msg: "test"}},
          Envelope,
          "application/json"
        )

      assert Jason.decode!(encoded) == %{
               "msg" => "test",
               "sub" => %{
                 "msg" => "test"
               }
             }
    end

    test "encodes repeated structs as JSON without implementing a JSON protocol" do
      encoded =
        Encoder.encode(
          %BatchReq{requests: [%Req{msg: "test1"}, %Req{msg: "test2"}]},
          BatchReq,
          "application/json"
        )

      assert Jason.decode!(encoded) == %{
               "requests" => [
                 %{"msg" => "test1"},
                 %{"msg" => "test2"}
               ]
             }
    end
  end
end
