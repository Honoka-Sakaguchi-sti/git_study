import { useEffect, useState } from "react";
import './App.css'

function App() {
  const [msg, setMsg] = useState("");
  const [input, setInput] = useState("");
  const [response, setResponse] = useState("");

  useEffect(() => {
    fetch("http://localhost:8000/api/hello")
      .then(res => res.json())
      .then(data => setMsg(data.message));
  }, []);

  // ここから追記
  const sendData = () => {
    fetch("http://localhost:8000/api/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ name: input }),
    })
      .then(res => res.json())
      .then(data => setResponse(data.received));
  };

  return (
    <div>
      <div>{msg}</div>
      <input
        value={input}
        onChange={e => setInput(e.target.value)}
        placeholder="名前を入力"
      />
      <button onClick={sendData}>送信</button>
      <div>サーバーから再送信: {response}</div>
    </div>
  );
}

export default App