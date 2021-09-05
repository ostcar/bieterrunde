# Bieterrunde

Programm für eine Bieterrunde


## Installieren

Zum Starten muss [go](https://golang.org/) installiert sein.

Anschließend kann es mit folgenden Befehlen gebaut und gestartet werden.

```
go install  github.com/ostcar/bieterrunde@latest
```

Anschließend kann http://localhost:9600 im browser aufgerufen werden.


## Entwicklung

Für die Entwicklung sollte folgende Software installiert sein:

* [go](https://golang.org/dl/)
* [elm](https://guide.elm-lang.org/install/elm.html)
* [Task](https://taskfile.dev/#/installation)



Anschließend kann mit folgendem Befehl der Server gestartet werden. Ändert sich
der Code oder die Configuration, dann wird der Server automatisch neu gestartet.

```
task start --watch
```
