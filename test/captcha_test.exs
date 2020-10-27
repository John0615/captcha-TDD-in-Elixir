defmodule CaptchaTest do
  use ExUnit.Case
  doctest Captcha

  @phone "18600010001"
  @code "1234"

  test "create captcha" do
    assert %{phone: "1", code: "a", remaining: 3} = Captcha.new("1", "a")
    assert %{phone: "2", code: "b"} = Captcha.new("2", "b")
  end

  defp with_captcha(_tags) do
    captcha = Captcha.new(@phone, @code)
    {:ok, captcha: captcha}
  end

  setup [:with_captcha]

  describe "#verify" do
    test "should return :ok with matched phone and code", %{captcha: captcha} do
      assert {:ok, _captcha} = Captcha.verify(captcha, "18600010001", "1234")
    end

    test "should return :mismatchaed with mismatched code", %{captcha: captcha} do
      assert {:mismatched, _captcha} = Captcha.verify(captcha, "18600010001", "2345")
    end

    test "should return :captcha_expired with mismatched phone", %{captcha: captcha} do
      assert {:captcha_expired, _captcha} = Captcha.verify(captcha, @phone <> "1", @code)
    end
  end

  describe "#verify with remaining" do
    test "should descrease remaining with matched phone and code", %{captcha: captcha} do
      assert {:ok, %{remaining: 2} = _captcha} = Captcha.verify(captcha, @phone, @code)
    end

    test "should decrease remaining with unmatched code", %{captcha: captcha} do
      assert {:mismatched, %{remaining: 2}} = Captcha.verify(captcha, @phone, @code <> "2")
    end

    test "remaining should unchanged with unmatched phone", %{captcha: captcha} do
      assert {:captcha_expired, %{remaining: 3}} = Captcha.verify(captcha, @phone <> "1", @code)
    end
  end

  describe "#verify with one time left" do
    defp set_remaining_to_one(%{captcha: captcha}) do
      {:ok, captcha: %{captcha | remaining: 1}}
    end

    setup [:set_remaining_to_one]

    test "should descrease remaining with matched phone and code", %{captcha: captcha} do
      assert {:ok, %{remaining: 0} = _captcha} = Captcha.verify(captcha, @phone, @code)
    end

    test "should decrease remaining with unmatched code", %{captcha: captcha} do
      assert {:mismatched, %{remaining: 0}} = Captcha.verify(captcha, @phone, @code <> "2")
    end

    test "remaining should unchanged with unmatched phone", %{captcha: captcha} do
      assert {:captcha_expired, %{remaining: 1}} = Captcha.verify(captcha, @phone <> "1", @code)
    end
  end

  describe "#veify with ran out remaining" do
    defp set_remaining_to_zero(%{captcha: captcha}) do
      {:ok, captcha: %{captcha | remaining: 0}}
    end

    setup [:set_remaining_to_zero]

    test "should return :captcha_expired even with unmatchaed phone and code", %{captcha: captcha} do
      assert {:captcha_expired, ^captcha} = Captcha.verify(captcha, @phone, @code <> "1")
    end

    test "should return :cpatcha_expired even with matched phone and code", %{captcha: captcha} do
      assert {:captcha_expired, ^captcha} = Captcha.verify(captcha, @phone, @code)
    end

    test "should return :cpatcha_expired and unchanged captcha even with unmatched phone", %{
      captcha: captcha
    } do
      assert {:captcha_expired, ^captcha} = Captcha.verify(captcha, @phone <> "1", @code)
    end
  end

  describe "#verify with multiple verifies" do
    test "should return :ok with 3 times verifies on matched phone on matched phone and code", %{
      captcha: captcha
    } do
      assert {:ok, captcha} = Captcha.verify(captcha, @phone, @code)
      assert {:ok, captcha} = Captcha.verify(captcha, @phone, @code)
      assert {:ok, captcha} = Captcha.verify(captcha, @phone, @code)
    end

    test "should return :captcha_expired on the 4th times verifies on matched phone on matched phone and code",
         %{captcha: captcha} do
      assert {:ok, captcha} = Captcha.verify(captcha, @phone, @code)
      assert {:ok, captcha} = Captcha.verify(captcha, @phone, @code)
      assert {:ok, captcha} = Captcha.verify(captcha, @phone, @code)
      assert {:captcha_expired, _captcha} = Captcha.verify(captcha, @phone, @code)
    end

    test "should return :captcha_expired on the 4th times verifies on matched phone on unmatched phone and code",
         %{captcha: captcha} do
      assert {:mismatched, captcha} = Captcha.verify(captcha, @phone, @code <> "1")
      assert {:mismatched, captcha} = Captcha.verify(captcha, @phone, @code <> "1")
      assert {:mismatched, captcha} = Captcha.verify(captcha, @phone, @code <> "1")
      assert {:captcha_expired, _captcha} = Captcha.verify(captcha, @phone, @code)
    end

    test "should return :captcha_expired on multiple verifies on matched phone on unmatched phone and code",
         %{captcha: captcha} do
      assert {:captcha_expired, captcha} = Captcha.verify(captcha, @phone <> "1", @code)
      assert {:captcha_expired, captcha} = Captcha.verify(captcha, @phone <> "1", @code)
      assert {:captcha_expired, captcha} = Captcha.verify(captcha, @phone <> "1", @code)

      assert {:captcha_expired, %{remaining: 3} = _captcha} =
               Captcha.verify(captcha, @phone <> "1", @code)
    end

    test "should return :ok on last verifies on mixed cases", %{captcha: captcha} do
      assert {:mismatched, captcha} = Captcha.verify(captcha, @phone, @code <> "1")
      assert {:mismatched, captcha} = Captcha.verify(captcha, @phone, @code <> "1")
      assert {:captcha_expired, captcha} = Captcha.verify(captcha, @phone <> "1", @code)
      assert {:ok, captcha} = Captcha.verify(captcha, @phone, @code)
    end
  end
end
