package server

import (
	"bytes"
	"fmt"
	"log"

	"github.com/johnfercher/maroto/pkg/consts"
	"github.com/johnfercher/maroto/pkg/pdf"
	"github.com/johnfercher/maroto/pkg/props"
)

// Bietervertrag creates the bietervertrag pdf for a bieter
func Bietervertrag(domain string, bieterID string, headerImage string, data pdfData) (*bytes.Buffer, error) {
	m := pdf.NewMaroto(consts.Portrait, consts.A4)

	// TODO: Remove
	//m.SetBorder(true)

	// Header
	m.Row(20, func() {
		// Adresse
		m.Col(6, func() {
			for i, line := range [...]string{
				"Solidarische Landwirtschaft Baarfood e. V",
				"Neckarstrasse 120",
				"78056 Villingen-Schwenningen",
				"www.baarfood.de",
			} {
				m.Text(line, props.Text{
					Size: 10,
					Top:  float64(i) * 3.5,
				})
			}
		})

		// Baarcode
		m.Col(3, func() {
			m.QrCode(fmt.Sprintf("%s/bieter/%s", domain, bieterID))
		})

		// Image
		m.Col(3, func() {
			err := m.Base64Image(headerImage, consts.Png, props.Rect{
				Center: true,
			})
			if err != nil {
				log.Printf("loading header image: %v", err)
				return
			}
		})
	})

	// Gemüsevertrag
	m.Row(15, func() {
		m.Col(12, func() {
			m.Text("Gemüsevertrag", props.Text{
				Size:  14,
				Style: consts.Bold,
				Align: consts.Center,
				Top:   5,
			})
		})
	})

	// Vertragstext
	m.Row(60, func() {
		m.Col(12, func() {
			m.Text(fmt.Sprintf(`
				Ich, %s (E-Mail: %s ), bin Mitglied im des Vereins Solidarische Landwirtschaft Baarfood e.V. 
				und möchte im Gemüsejahr 2022/23 (April 2022 – März 2023) einen Gemüseanteil beziehen.`, data.Name, data.Mail),
			)
			m.Text(
				`Nach erfolgreicher Bieterrunde schließe ich mit dem Verein Solidarische Landwirtschaft 
				Baarfood e.V. diesen Gemüsevertrag ab.`,
				props.Text{
					Top: 10,
				},
			)

			m.Text(
				`Die Gemüsevertrag gilt von April 2021 bis März 2022 (=12 Monate). 
				Ich kann mein Gemüse wöchentlich an einer vorher festgelegten Verteilstelle abholen. 
				Ich respektiere die in den Verteilstellen genannten Anteilsmengen und Abholfristen. 
				Ich habe keinen Anspruch auf eine bestimmte Menge und Qualität der Produkte. 
				Sollte es mir vorübergehend nicht möglich sein, meinen Pflichten (Abholung) nach zu kommen, 
				so sorge ich selbst in diesem Zeitraum für einen Ersatz. Im Falle einer Urlaubsvertretung weise 
				ich persönlich in die Abholmodalitäten ein. Ein finanzieller Ausgleich wird privat organisiert. 
				Die endgültige Abgabe meines Anteils im laufenden Jahr ist nur möglich, wenn ein anderes 
				Vereinsmitglied, das bisher keinen Ernteanteil bezieht, oder ein neues Mitglied, den 
				oben genannten monatlichen finanziellen Beitrag für die verbleibenden Monate übernimmt. 
				Erst ab diesem Zeitpunkt erfolgt der Lastschrifteinzug von diesem neuen Mitglied.`,
				props.Text{
					Top: 20,
					// Style: consts.Italic,
				},
			)
		})
	})

	// Verteilstelle
	m.Row(5, func() {
		m.Col(12, func() {
			m.Text(
				fmt.Sprintf(`Ich hole meinen Antreil in der Verteilstelle in %s.`, data.Verteilstelle),
			)
		})
	})

	// Abbuchung
	m.Row(5, func() {
		m.Col(12, func() {
			m.Text(fmt.Sprintf(`Die Abbuchung meines Beitrages für den Ernteanteil erfolgt von April 2022 bis März 2023 %s.`, data.Abbuchung))
		})
	})

	// Datum Unterschrift
	m.Row(20, func() {
		m.Col(6, func() {
			m.Text("_________________________",
				props.Text{
					Top: 10,
				},
			)

			m.Text("Ort, Datum",
				props.Text{
					Top:  15,
					Size: 8,
				},
			)
		})
		m.Col(6, func() {
			m.Text("_________________________",
				props.Text{
					Top: 10,
				},
			)
			m.Text("Unterschrift", props.Text{
				Top:  15,
				Size: 8,
			})
		})
	})

	// SEPA
	m.Row(15, func() {
		m.Col(12, func() {
			m.Text("SEPA Lastschriftmandat", props.Text{
				Size:  14,
				Style: consts.Bold,
				Align: consts.Center,
				Top:   5,
			})
		})
	})

	// Gläubiger-Identifikationsnummer
	m.Row(5, func() {
		m.Col(4, func() {
			m.Text(`Gläubiger-Identifikationsnummer:`)

		})
		m.Col(12, func() {
			m.Text(`DE62ZZZ00001997635`, props.Text{
				Style: consts.Bold,
			})
		})
	})

	// Mandatsreferenz
	m.Row(5, func() {
		m.Col(3, func() {
			m.Text(`Mandatsreferenz: `)
		})
		m.Col(12, func() {
			m.Text(fmt.Sprintf(` 22%s`, bieterID), props.Text{
				Style: consts.Bold,
			})
		})
	})

	// Abbuchung
	m.Row(6, func() {
		m.Col(12, func() {
			if data.Abbuchung == 1 {
				m.Text("Die Abbuchung erfolgt am 1. April 2022")
			} else {
				m.Text("Die Abbuchung erfolgt am ersten Werktag eines Monats von April 2022 bis März 2023")
			}
		})
	})

	m.Row(6, func() {
		m.Col(12, func() {
			// if data == 1 {
			// 	m.Text("Die Abbuchung erfolgt am 1. April 2022")
			// } else {
			// 	m.Text("Die Abbuchung erfolgt am ersten Werktag eines Monats von April 2022 bis März 2023")
			// }
			euro := data.offer / 100
			cent := data.offer % 100
			m.Text(fmt.Sprintf("Der Betrag lautet: %d,%02d €", euro, cent), props.Text{
				Style: consts.Bold,
			})
		})
	})
	// Sepa-Text
	m.Row(30, func() {
		m.Col(12, func() {
			m.Text(`
			Ich ermächtige den Verein Solidarische Landwirtschaft Baarfood e.V. 
			Lastschriften von meinem Konto einzuziehen. Zugleich weise ich mein 
			Kreditinstitut an, die von Solidarische Landwirtschaft Baarfood e.V. 
			auf mein Konto gezogenen Lastschriften einzulösen.
			`,
			)

			m.Text(
				`Ich kann innerhalb von acht Wochen, beginnend mit dem Belastungsdatum,
				die Erstattung des belasteten Betrages verlangen. Es gelten dabei die
				mit meinem Kreditinstitut vereinbarten Bedingungen.
				`,
				props.Text{
					Top: 12,
				},
			)

			m.Text(
				`Ist eine Abbuchung nicht möglich, so geht die Rückbuchungsgebühr zu meinen Lasten.`,
				props.Text{
					Top: 20,
				},
			)
		})
	})

	m.Row(10, func() {
		m.Col(12, func() {
			kontoinhaber := data.Kontoinhaber
			if len(kontoinhaber) == 0 {
				kontoinhaber = data.Name
			}
			m.Text(fmt.Sprintf(`Kontoinhaber: %s`, kontoinhaber))
			m.Text(fmt.Sprintf(`Adresse: %s`, data.Adresse),
				props.Text{
					Top: 5,
				},
			)
			m.Text(fmt.Sprintf(`IBAN: %s`, data.IBAN),
				props.Text{
					Top: 10,
				},
			)
		})
	})

	// Datum Unterschrift
	m.Row(20, func() {
		m.Col(6, func() {
			m.Text("_________________________",
				props.Text{
					Top: 10,
				},
			)

			m.Text("Ort, Datum",
				props.Text{
					Top:  15,
					Size: 8,
				},
			)
		})

		m.Col(6, func() {
			m.Text("_________________________",
				props.Text{
					Top: 10,
				},
			)
			m.Text("Unterschrift Kontoinhaber", props.Text{
				Top:  15,
				Size: 8,
			})
		})
	})

	pdfile, err := m.Output()
	if err != nil {
		return nil, fmt.Errorf("creating pdf: %w", err)
	}

	return &pdfile, nil
}

type pdfData struct {
	Name          string        `json:"name"`
	Mail          string        `json:"mail"`
	Verteilstelle verteilstelle `json:"verteilstelle"`
	Abbuchung     abbuchung     `json:"abbuchung"`
	Kontoinhaber  string        `json:"kontoinhaber"`
	Adresse       string        `json:"adresse"`
	IBAN          string        `json:"IBAN"`
	offer         int
}

type verteilstelle int

func (v verteilstelle) String() string {
	switch v {
	case 1:
		return "Villingen"
	case 2:
		return "Schwenningen"
	case 3:
		return "Überauchen (Acker)"
	}
	return "UNGÜLTIG"
}

type abbuchung int

func (a abbuchung) String() string {
	if a == 1 {
		return "Jährlich"
	}
	return "Monatlich"
}
