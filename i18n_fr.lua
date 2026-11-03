-- Translations for quickcalc.koplugin, merged into the shared i18n table
-- from main.lua. Keys share one table with every other plugin: a key that
-- another plugin translates differently is a conflict (tools/i18n_conflicts).
return {
    ["Calculator"]                     = { fr = "Calculatrice", es = "Calculadora", de = "Rechner" },
    ["Calculator with scientific functions, memory and history, plus VAT and percentages, bill split with tip, and loan and savings forms."] = {
        fr = "Calculatrice avec fonctions scientifiques, mémoire et historique, plus TVA et pourcentages, partage d'addition avec pourboire, prêt et épargne.",
        es = "Calculadora con funciones científicas, memoria e historial, además de IVA y porcentajes, división de la cuenta con propina, préstamo y ahorro.",
        de = "Rechner mit wissenschaftlichen Funktionen, Speicher und Verlauf, dazu MwSt. und Prozente, Rechnung teilen mit Trinkgeld, Kredit und Sparen.",
    },

    -- Modes and menu ("History" and "Help" as other plugins translate them)
    ["History"]                        = { fr = "Historique", es = "Historial", de = "Verlauf" },
    ["Help"]                           = { fr = "Aide", es = "Ayuda", de = "Hilfe" },
    ["Percentages"]                    = { fr = "Pourcentages", es = "Porcentajes", de = "Prozente" },
    ["Bill split & tip"]               = { fr = "Addition & pourboire", es = "Dividir cuenta y propina", de = "Rechnung & Trinkgeld" },
    ["Loan & savings"]                 = { fr = "Prêt & épargne", es = "Préstamo y ahorro", de = "Kredit & Sparen" },
    ["Show scientific keys"]           = { fr = "Afficher les touches scientifiques", es = "Mostrar teclas científicas", de = "Wissenschaftliche Tasten zeigen" },
    ["Hide scientific keys"]           = { fr = "Masquer les touches scientifiques", es = "Ocultar teclas científicas", de = "Wissenschaftliche Tasten ausblenden" },

    -- Calculator
    ["Hist"]                           = { fr = "Hist", es = "Hist", de = "Verl." },
    ["Degrees"]                        = { fr = "Degrés", es = "Grados", de = "Grad" },
    ["Radians"]                        = { fr = "Radians", es = "Radianes", de = "Bogenmaß" },
    ["Cannot divide by zero"]          = { fr = "Division par zéro impossible", es = "No se puede dividir entre cero", de = "Division durch null nicht möglich" },
    ["Overflow: number too large"]     = { fr = "Dépassement : nombre trop grand", es = "Desbordamiento: número demasiado grande", de = "Überlauf: Zahl zu groß" },
    ["Undefined result"]               = { fr = "Résultat indéfini", es = "Resultado indefinido", de = "Ergebnis nicht definiert" },
    ["Incomplete expression"]          = { fr = "Expression incomplète", es = "Expresión incompleta", de = "Unvollständiger Ausdruck" },
    ["No calculations yet."]           = { fr = "Aucun calcul pour l'instant.", es = "Todavía no hay cálculos.", de = "Noch keine Berechnungen." },
    ["Tap a result to reuse it."]      = { fr = "Touchez un résultat pour le réutiliser.", es = "Toque un resultado para reutilizarlo.", de = "Tippen Sie auf ein Ergebnis, um es weiterzuverwenden." },
    ["Clear history"]                  = { fr = "Effacer l'historique", es = "Borrar el historial", de = "Verlauf löschen" },
    ["Clear the history?"]             = { fr = "Effacer l'historique ?", es = "¿Borrar el historial?", de = "Verlauf löschen?" },

    -- Form tabs and options
    ["VAT"]                            = { fr = "TVA", es = "IVA", de = "MwSt." },
    ["Discount"]                       = { fr = "Remise", es = "Descuento", de = "Rabatt" },
    ["% change"]                       = { fr = "Évolution %", es = "Variación %", de = "Änderung %" },
    ["X % of Y"]                       = { fr = "X % de Y", es = "X % de Y", de = "X % von Y" },
    ["Loan"]                           = { fr = "Prêt", es = "Préstamo", de = "Kredit" },
    ["Savings"]                        = { fr = "Épargne", es = "Ahorro", de = "Sparen" },
    ["Excl. → incl. VAT"]              = { fr = "HT → TTC", es = "Sin IVA → con IVA", de = "Netto → brutto" },
    ["Incl. → excl. VAT"]              = { fr = "TTC → HT", es = "Con IVA → sin IVA", de = "Brutto → netto" },
    ["years"]                          = { fr = "ans", es = "años", de = "Jahre" },
    ["months"]                         = { fr = "mois", es = "meses", de = "Monate" },

    -- Fields
    ["Amount excl. VAT"]               = { fr = "Montant HT", es = "Importe sin IVA", de = "Nettobetrag" },
    ["Amount incl. VAT"]               = { fr = "Montant TTC", es = "Importe con IVA", de = "Bruttobetrag" },
    ["VAT rate (%)"]                   = { fr = "Taux de TVA (%)", es = "Tipo de IVA (%)", de = "MwSt.-Satz (%)" },
    ["Price"]                          = { fr = "Prix", es = "Precio", de = "Preis" },
    ["Discount (%)"]                   = { fr = "Remise (%)", es = "Descuento (%)", de = "Rabatt (%)" },
    ["Initial value"]                  = { fr = "Valeur de départ", es = "Valor inicial", de = "Anfangswert" },
    ["Final value"]                    = { fr = "Valeur d'arrivée", es = "Valor final", de = "Endwert" },
    ["Percentage X (%)"]               = { fr = "Pourcentage X (%)", es = "Porcentaje X (%)", de = "Prozentsatz X (%)" },
    ["Value Y"]                        = { fr = "Valeur Y", es = "Valor Y", de = "Wert Y" },
    ["Bill total"]                     = { fr = "Total de l'addition", es = "Total de la cuenta", de = "Rechnungsbetrag" },
    ["People"]                         = { fr = "Personnes", es = "Personas", de = "Personen" },
    ["Tip (%)"]                        = { fr = "Pourboire (%)", es = "Propina (%)", de = "Trinkgeld (%)" },
    ["Amount borrowed"]                = { fr = "Montant emprunté", es = "Importe prestado", de = "Kreditbetrag" },
    ["Annual rate (%)"]                = { fr = "Taux annuel (%)", es = "Interés anual (%)", de = "Jahreszins (%)" },
    ["Duration"]                       = { fr = "Durée", es = "Duración", de = "Dauer" },
    ["Initial amount"]                 = { fr = "Montant initial", es = "Importe inicial", de = "Anfangsbetrag" },
    ["Monthly deposit"]                = { fr = "Versement mensuel", es = "Aportación mensual", de = "Monatliche Einzahlung" },

    -- Results
    ["Excl. VAT"]                      = { fr = "HT", es = "Sin IVA", de = "Netto" },
    ["Incl. VAT"]                      = { fr = "TTC", es = "Con IVA", de = "Brutto" },
    ["Final price"]                    = { fr = "Prix final", es = "Precio final", de = "Endpreis" },
    ["Saving"]                         = { fr = "Économie", es = "Ahorro", de = "Ersparnis" },
    ["Change"]                         = { fr = "Évolution", es = "Variación", de = "Änderung" },
    ["Difference"]                     = { fr = "Différence", es = "Diferencia", de = "Differenz" },
    ["Y + X %"]                        = { fr = "Y + X %", es = "Y + X %", de = "Y + X %" },
    ["Y − X %"]                        = { fr = "Y − X %", es = "Y − X %", de = "Y − X %" },
    ["Tip"]                            = { fr = "Pourboire", es = "Propina", de = "Trinkgeld" },
    ["Total with tip"]                 = { fr = "Total avec pourboire", es = "Total con propina", de = "Gesamt mit Trinkgeld" },
    ["Per person"]                     = { fr = "Par personne", es = "Por persona", de = "Pro Person" },
    ["Monthly payment"]                = { fr = "Mensualité", es = "Cuota mensual", de = "Monatsrate" },
    ["Total repaid"]                   = { fr = "Total remboursé", es = "Total devuelto", de = "Gesamt zurückgezahlt" },
    ["Total interest"]                 = { fr = "Total des intérêts", es = "Intereses totales", de = "Zinsen gesamt" },
    ["Final balance"]                  = { fr = "Capital final", es = "Saldo final", de = "Endguthaben" },
    ["Total deposited"]                = { fr = "Total versé", es = "Total aportado", de = "Eingezahlt gesamt" },
    ["Interest earned"]                = { fr = "Intérêts gagnés", es = "Intereses ganados", de = "Zinserträge" },

    -- Form errors
    ["The initial value can't be 0."]  = { fr = "La valeur de départ ne peut pas être 0.", es = "El valor inicial no puede ser 0.", de = "Der Anfangswert darf nicht 0 sein." },
    ["People must be a whole number, at least 1."] = { fr = "Le nombre de personnes doit être un entier, au moins 1.", es = "El número de personas debe ser un entero, al menos 1.", de = "Die Personenzahl muss eine ganze Zahl ab 1 sein." },
    ["The duration must be a whole number of months."] = { fr = "La durée doit être un nombre entier de mois.", es = "La duración debe ser un número entero de meses.", de = "Die Dauer muss eine ganze Zahl von Monaten sein." },
    ["The rate must be above −100 %."] = { fr = "Le taux doit être supérieur à −100 %.", es = "El tipo debe ser superior a −100 %.", de = "Der Satz muss über −100 % liegen." },
}
