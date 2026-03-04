# 📅 BookSpace

**App aziendale per la gestione delle prenotazioni di sale e risorse**

Sviluppata da **Riccardo Ravenna**

---

## 📖 Descrizione

BookSpace è un sistema completo di booking interno aziendale che permette ai dipendenti di prenotare sale riunioni, postazioni desk e attrezzature. Include un pannello di amministrazione avanzato, notifiche email automatiche e un'app mobile nativa per Android e iOS.

Il progetto nasce con l'obiettivo di simulare un prodotto reale in un contesto aziendale con 20-30 utenti, coprendo l'intero ciclo di sviluppo: backend API, frontend web e app mobile.

---

## 🚀 Funzionalità principali

- **Autenticazione** — Registrazione, login con JWT, reset password via email
- **Prenotazioni** — Creazione, cancellazione e visualizzazione prenotazioni
- **Prenotazioni ricorrenti** — Ripetizione settimanale fino a 4 settimane, con gestione automatica dei conflitti
- **Calendario** — Vista mensile con colori per tipo di risorsa
- **Notifiche email** — Conferma prenotazione, cancellazione e notifica agli utenti coinvolti
- **Profilo utente** — Modifica dati personali e cambio password con validazione sicura
- **Pannello admin** — Gestione prenotazioni, risorse, utenti e log attività
- **Log attività** — Storico completo di tutte le azioni nel sistema
- **Backup automatico** — Backup del database su Google Drive via OAuth2
- **App mobile** — Applicazione Flutter nativa per Android e iOS

---

## 🛠️ Stack tecnologico

### Backend
| Tecnologia | Utilizzo |
|---|---|
| Node.js + Express | API REST |
| PostgreSQL | Database relazionale |
| JWT | Autenticazione stateless |
| bcrypt | Hashing password |
| Nodemailer | Invio email transazionali |
| Google Drive API | Backup automatico |

### Frontend Web
| Tecnologia | Utilizzo |
|---|---|
| HTML / CSS / JavaScript | Interfaccia web single-page |
| Dark UI custom | Design system proprietario |

### App Mobile
| Tecnologia | Utilizzo |
|---|---|
| Flutter (Dart) | App nativa Android/iOS |
| Provider | State management |
| Dio | HTTP client con interceptor JWT |
| Go Router | Navigazione dichiarativa |
| Flutter Secure Storage | Token storage sicuro |
| Table Calendar | Calendario interattivo |

---

## 📁 Struttura del progetto

```
booking_interno/
├── backend/
│   ├── routes/
│   │   ├── auth.js          # Login, register, reset password
│   │   ├── bookings.js      # CRUD prenotazioni + ricorrenza
│   │   ├── resources.js     # Gestione risorse
│   │   ├── users.js         # Profilo e gestione utenti
│   │   └── logs.js          # Log attività admin
│   ├── middleware/
│   │   ├── auth.js          # Autenticazione JWT
│   │   ├── mailer.js        # Template email
│   │   └── logger.js        # Activity logger
│   ├── db/
│   │   └── pool.js          # Connessione PostgreSQL
│   └── server.js
├── lib/                     # App Flutter
│   ├── screens/
│   │   ├── auth/            # Login, registrazione
│   │   ├── dashboard/       # Dashboard principale
│   │   ├── resources/       # Lista e prenotazione risorse
│   │   ├── bookings/        # Le mie prenotazioni
│   │   ├── calendar/        # Calendario mensile
│   │   ├── profile/         # Profilo utente
│   │   └── admin/           # Pannello amministratore
│   ├── providers/
│   │   └── auth_provider.dart
│   └── services/
│       └── api_service.dart
└── index.html               # Frontend web
```

---

## ⚙️ Installazione e avvio

### Prerequisiti
- Node.js >= 18
- PostgreSQL >= 14
- Flutter >= 3.0

### Backend

```bash
cd backend
npm install
```

Crea un file `.env`:
```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=booking_interno
DB_USER=postgres
DB_PASSWORD=tua_password
JWT_SECRET=tuo_secret
EMAIL_USER=tua_email@gmail.com
EMAIL_PASS=tua_app_password
```

Avvia il server:
```bash
node server.js
```

### Frontend web
Apri `index.html` con un server locale (es. Live Server su VS Code).

### App mobile
```bash
flutter pub get
flutter run
```

---

## 🔐 Sicurezza

- Password con requisiti minimi: 8 caratteri, 1 maiuscola, 1 numero, 1 simbolo
- Token JWT con scadenza
- Hashing password con bcrypt
- Token storage sicuro su mobile (flutter_secure_storage)
- Ruoli utente: `admin` e `employee`
- Validazione input lato server con express-validator

---

## 📸 Screenshot

> *Screenshots disponibili nella cartella `/screenshots`*

---

## 👤 Autore

**Riccardo Ravenna**  
Progetto personale sviluppato per dimostrare competenze full-stack in ambito aziendale.
