defmodule CaptchaHandler do
  use GenServer

  def start_link([phone, code]) do
    GenServer.start_link(__MODULE__, {:ok, phone, code})
  end

  def init({:ok, phone, code}) do
    {:ok, Captcha.new(phone, code)}
  end

  def verify(handler, phone, code) do
    GenServer.call(handler, {:verify, phone, code})
  end

  def handle_call({:verify, phone, code}, _from, captcha) do
    {result, new_captcha} = Captcha.verify(captcha, phone, code)
    {:reply, result, new_captcha}
  end
end
