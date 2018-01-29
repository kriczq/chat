Recenzja - https://github.com/Konrad337/haskell

Projekt jest napisany schludnie, czytelnie i zrozumiale, jednakże w całym projekcie brakuje komentarzy do funkcji. Po przeanalizowaniu funkcji, można bez problemu dojść do wniosku co ona robi, natomiast jest to marnowanie czasu, który można byłoby zaoszczędzić komentarzem. Przy deklaracji modułów brakuje deklaracji funkcji eksportowanych, w związku z czym podczas importów importujemy wszystkie funkcje z danego modułu, co nie jest do końca OK. Co więcej, nazwy funkcji takie jak f i s nie do końca sugerują nam własności funkcji, ich celu. W kodzie są zachowane odstępy, co zwiększa czytelność - jest to cecha jak najbardziej in plus.<br />
Komentarze nie są napisane w stylu, w którym zostałyby odpowiednio zinterpretowane przez Haddocka - szkoda, gdyż Haddock oszczędza dużo czasu na dokumentacji kodu.<br />
W projekcie brakuje testów, nie zauważyłem napisanego żadnego testu.<br />
Nie rozumiem też, dlaczego w projekcie mamy duplikaty tych samych modułów, w folderze app i src znajdują się te same moduły, co w folderze out.<br />
Treści commitów są czytelne, jednakże powielają sie, a dodatkowo jest ich tak mało (7), że ciężko cokolwiek na ich temat powiedzieć, gdyż nazwy commitów docenia się dopiero w większym projekcie realizowanym przez grupę programistów.<br />
Warto byłoby też dodać do pliku .gitignore adres folderu .idea, którego nie powinno się wrzucać do repozytorium, jest to zbiór plików użytecznych lokalnie, służących do konfigurowania naszego IDE.<br />
Poza tym, instrukcja uruchomienia jest dość dokładna, brakuje mi w niej (mimo, że wiem co zrobić) informacji dla laika - pierwsze pasuje uruchomić `stack build` i `stack ghci`, a dopiero potem wpisać komendę napisaną przez autora powyższego projektu.
