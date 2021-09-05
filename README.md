# Bieterrunde

Programm für eine Bieterrunde


## Starten

Zum Starten muss [go](https://golang.org/) installiert sein.

Anschließend kann es mit folgenden Befehlen gebaut und gestartet werden.

```
go build
./bieterrunde
```

Anschließend kann http://localhost:9600 im browser aufgerufen werden.


## Entwicklung

Für die Entwicklung muss zusätzlich [elm](https://elm-lang.org/) installiert sein.


### Automatischer Restart bei Code Änderungen

Für die Entwicklung bietet es sich an zusätzlich [Task](https://taskfile.dev/) zu installieren.

```
go install github.com/go-task/task/v3/cmd/task@latest
```

Anschließend kann der Server mit 

```
task --watch
```

gestartet werden. Ändernt sich der Sourcecode vom Server oder vom Client, dann wird der Server automatisch neu gestartet.
