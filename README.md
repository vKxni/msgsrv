```
$ iex -S mix

$ {:ok, pid} = Msgsrv.Server.start_link()
:ok

$ Msgsrv.Server.join(pid, "username") 
:ok

$ Msgsrv.Server.send_message(pid, "hi there")
:ok
```

```
$ Msgsrv.Server.get_messages(pid)
[...]

$ Msgsrv.Server.get_users(pid)
{[...]}
```

```
$ :ets.lookup(:msgsrv_table, pid) 
[{#PID<...>, "hi there"}]
...
