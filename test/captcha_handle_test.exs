defmodule CaptchahandlerTest do
  use ExUnit.Case, async: true

  @phone "18600010002"
  @code "1122"

  test "spawns captcha handler", %{handler: captcha_handler} do
    assert Captcha_handler != nil
  end

  setup do
    captcha_handler = start_supervised!({CaptchaHandler, [@phone, @code]})
    {:ok, handler: captcha_handler}
  end

  describe "sequential verify" do
    test "returns :ok, with matched and code", %{handler: captcha_handler} do
      assert :ok = CaptchaHandler.verify(captcha_handler, @phone, @code)
    end

    test "returns :mismatched with mismatched code", %{handler: captcha_handler} do
      assert :mismatched = CaptchaHandler.verify(captcha_handler, @phone, @code <> "1")
    end

    test "returns :captcha_expired with mismatched phone", %{handler: captcha_handler} do
      assert :captcha_expired = CaptchaHandler.verify(captcha_handler, @phone <> "1", @code)
    end

    test "still :ok for matched phone and code 3 times", %{handler: captcha_handler} do
      assert :ok = CaptchaHandler.verify(captcha_handler, @phone, @code)
      assert :ok = CaptchaHandler.verify(captcha_handler, @phone, @code)
      assert :ok = CaptchaHandler.verify(captcha_handler, @phone, @code)
    end

    test "still :mismatched with mismatched phone and code 3 times", %{handler: captcha_handler} do
      assert :mismatched = CaptchaHandler.verify(captcha_handler, @phone, @code <> "1")
      assert :mismatched = CaptchaHandler.verify(captcha_handler, @phone, @code <> "1")
      assert :mismatched = CaptchaHandler.verify(captcha_handler, @phone, @code <> "1")
    end

    test "got :captcha_expired with matched phone and code after 3 times :ok", %{
      handler: captcha_handler
    } do
      assert :ok = CaptchaHandler.verify(captcha_handler, @phone, @code)
      assert :ok = CaptchaHandler.verify(captcha_handler, @phone, @code)
      assert :ok = CaptchaHandler.verify(captcha_handler, @phone, @code)
      assert :captcha_expired = CaptchaHandler.verify(captcha_handler, @phone, @code)
    end

    test "got :captcha_expired with matched phone and code after 3 times failed", %{
      handler: captcha_handler
    } do
      assert :mismatched = CaptchaHandler.verify(captcha_handler, @phone, @code <> "1")
      assert :mismatched = CaptchaHandler.verify(captcha_handler, @phone, @code <> "1")
      assert :mismatched = CaptchaHandler.verify(captcha_handler, @phone, @code <> "1")
      assert :captcha_expired = CaptchaHandler.verify(captcha_handler, @phone, @code <> "1")
    end

    test "verify with mixed cases", %{handler: captcha_handler} do
      assert :mismatched = CaptchaHandler.verify(captcha_handler, @phone, @code <> "1")
      assert :captcha_expired = CaptchaHandler.verify(captcha_handler, @phone <> "1", @code)
      assert :ok = CaptchaHandler.verify(captcha_handler, @phone, @code)
      assert :captcha_expired = CaptchaHandler.verify(captcha_handler, @phone <> "1", @code)
      assert :ok = CaptchaHandler.verify(captcha_handler, @phone, @code)
      assert :captcha_expired = CaptchaHandler.verify(captcha_handler, @phone <> "1", @code)
    end
  end

  describe "verify with concurrency" do
    test "should got 3 :ok for 3 conncurrent invoke", %{handler: captcha_handler} do
      assert [:ok, :ok, :ok] ==
               [
                 Task.async(fn -> CaptchaHandler.verify(captcha_handler, @phone, @code) end),
                 Task.async(fn -> CaptchaHandler.verify(captcha_handler, @phone, @code) end),
                 Task.async(fn -> CaptchaHandler.verify(captcha_handler, @phone, @code) end)
               ]
               |> Task.await_many()
    end

    test "concurrent with mixed cases", %{handler: captcha_handler} do
      results =
        [
          Task.async(fn -> CaptchaHandler.verify(captcha_handler, @phone, @code) end),
          Task.async(fn -> CaptchaHandler.verify(captcha_handler, @phone, @code <> "1") end),
          Task.async(fn -> CaptchaHandler.verify(captcha_handler, @phone, @code) end),
          Task.async(fn -> CaptchaHandler.verify(captcha_handler, @phone, @code <> "1") end)
        ]
        |> Task.await_many()

      assert [] == results -- [:ok, :ok, :mismatched, :captcha_expired]
    end
  end
end
