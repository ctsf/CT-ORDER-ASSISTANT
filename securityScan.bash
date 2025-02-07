sf scanner run --format csv --outfile CodeAnalyzerGeneral.csv --target ./ --category Security
sf scanner run dfa --format csv --outfile CodeAnalyzerDFA.csv --target ./ --projectdir ./ --category Security
sf scanner run --engine pmd-appexchange --format csv --outfile CodeAnalyzerPmdAppExchange.csv --target ./