# Security Policy

Dette projekt er en teknisk prototype og må ikke betragtes som produktionsklar uden yderligere sikkerhedstiltag.

## Følsomme filer

Følgende må ikke commit’es:

- Private nøgler
- Certifikater
- API keys
- Tokens
- `.env`-filer
- Produktionskonfiguration

Mappen `cert/` er ignoreret af git bortset fra `.gitkeep`.

## Anbefalinger før offentlig eksponering

Før løsningen eksponeres uden for et lukket testmiljø, bør følgende implementeres:

- HTTPS med betroet certifikat
- Autentificering
- Autorisation
- Rate limiting
- Inputvalidering
- Logging og audit
- TURN-server med adgangskontrol
- Hardenet reverse proxy
- Afgrænsning af adgang til operator-interface

## WebRTC-specifikke forhold

WebRTC kan afsløre netværksoplysninger via ICE-kandidater afhængigt af browser og konfiguration. Gennemgå STUN/TURN-konfiguration før brug i følsomme miljøer.

## Rapportering

Dette er et personligt portfolio-/prototypeprojekt. Eventuelle sikkerhedsfund kan rapporteres direkte til repository-ejeren.
