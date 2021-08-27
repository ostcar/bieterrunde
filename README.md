# Bieterrunde

Programm für eine Bieterrunde


## Starten

Zum Starten muss [go](https://golang.org/) installiert sein.

Anschließend kann es mit folgenden Befehlen gebaut und gestartet werden.

```
go build
./bieterrunde
```


## Beispiele

Aktuelle Daten abrufen:
```
curl -c cookies -b cookies localhost:8080/
```

Nutzer per Nummer auswählen:
```
curl -c cookies -b cookies localhost:8080/?user=32283872
```

Nutzer anlegen:

```
curl -c cookies -b cookies localhost:8080/create
```


Nutzer bearbeiten:
```
curl -c cookies -b cookies -X POST --data "name=hugo" --data "adresse=gartenstraße 5" --data "iban=AT483200000012345864" localhost:8080
```

Als Admin anmelden:
```
curl -c cookies -b cookies localhost:8080/admin/login --data "password=ADMIN PASSWORD"
```

Als Admin die alle Daten abrufen:
```
curl -c cookies -b cookies localhost:8080/admin
```
