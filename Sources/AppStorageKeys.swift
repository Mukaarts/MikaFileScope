// AppStorageKeys.swift
// MikaFileScope
//
// Die Schlüssel der Benutzereinstellungen an einer Stelle. Zuvor stand
// "showMenubar" dreimal als Zeichenkette im Code — ein Tippfehler beim Ändern
// wäre beim Übersetzen nicht aufgefallen.

enum AppStorageKeys {
    static let showMenubar = "showMenubar"
    /// Ob die einmalige Erklärung vor dem ersten Ordnerzugriff schon gelaufen ist.
    static let accessIntroSeen = "accessIntroSeen"
}
