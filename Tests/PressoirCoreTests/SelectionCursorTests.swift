import Testing

@testable import PressoirCore

@Suite("Navigation clavier dans la liste")
struct SelectionCursorTests {
    @Test("Descendre puis monter déplace la sélection d'un cran")
    func movesByOne() {
        let cursor = SelectionCursor(count: 3)

        #expect(cursor.movingDown().index == 1)
        #expect(cursor.movingDown().movingUp().index == 0)
    }

    @Test("La sélection boucle aux extrémités")
    func wrapsAround() {
        let cursor = SelectionCursor(count: 3)

        #expect(cursor.movingUp().index == 2)
        #expect(cursor.movingUp().movingDown().index == 0)
    }

    @Test("Une liste vide n'a pas de sélection")
    func emptyListHasNoSelection() {
        let cursor = SelectionCursor(count: 0)

        #expect(cursor.index == nil)
        #expect(cursor.movingDown().index == nil)
    }

    @Test("Quand la liste rétrécit, la sélection reste dans les bornes")
    func clampsOnResize() {
        let cursor = SelectionCursor(count: 5).movingUp()

        #expect(cursor.resized(to: 2).index == 1)
        #expect(cursor.resized(to: 0).index == nil)
    }

    @Test("Les raccourcis 1 à 9 visent la ligne correspondante si elle existe")
    func digitShortcut() {
        let cursor = SelectionCursor(count: 3)

        #expect(cursor.selecting(shortcut: 2)?.index == 1)
        #expect(cursor.selecting(shortcut: 4) == nil)
        #expect(cursor.selecting(shortcut: 0) == nil)
    }
}
