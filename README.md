# Bieterrunde

Programm für eine Bieterrunde.


## Installieren

### Fertige Binaries

Die einfachste möglichkeit das Tool zu installieren ist mittels der fertigen
binaries. Diese können von
[github](https://github.com/ostcar/bieterrunde/releases/latest) runtergeladen
werden.


### Mit Go

Wenn go installiert ist, kann es auch mit go installiert werden:

```
go install  github.com/ostcar/bieterrunde@latest
```


## Starten

Das installierte Programm ist ein einzelnes Binary. Dieses kann direkt gestartet
werden. Weitere zwingende Abhängigkeiten gibt es nicht. 

Nach dem starten kann die Anwendung im Browser aufgerufen werde: http://localhost:9600


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
