const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

const sendResetEmail = async (email, name, resetLink) => {
  await transporter.sendMail({
    from: `"BookSpace" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: 'Reset della tua password — BookSpace',
    html: `
      <div style="font-family:sans-serif;max-width:500px;margin:0 auto;padding:32px;background:#f9f9f9;border-radius:12px;">
        <h2 style="color:#5b7cfa;">BookSpace</h2>
        <p>Ciao <strong>${name}</strong>,</p>
        <p>Hai richiesto il reset della password. Clicca il bottone qui sotto per impostarne una nuova:</p>
        <a href="${resetLink}" style="display:inline-block;margin:24px 0;padding:12px 28px;background:#5b7cfa;color:#fff;border-radius:8px;text-decoration:none;font-weight:600;">Reset Password</a>
        <p style="color:#999;font-size:12px;">Il link scade tra 1 ora. Se non hai richiesto il reset ignora questa email.</p>
      </div>
    `,
  });
};

const sendBookingConfirmEmail = async (email, name, booking) => {
  const startDate = new Date(booking.start_time).toLocaleDateString('it-IT', { weekday: 'long', day: '2-digit', month: 'long', year: 'numeric' });
  const startTime = new Date(booking.start_time).toLocaleTimeString('it-IT', { hour: '2-digit', minute: '2-digit' });
  const endTime = new Date(booking.end_time).toLocaleTimeString('it-IT', { hour: '2-digit', minute: '2-digit' });

  await transporter.sendMail({
    from: `"BookSpace" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: `Prenotazione confermata: ${booking.title} — BookSpace`,
    html: `
      <div style="font-family:sans-serif;max-width:500px;margin:0 auto;padding:32px;background:#f9f9f9;border-radius:12px;">
        <h2 style="color:#5b7cfa;">📅 BookSpace</h2>
        <p>Ciao <strong>${name}</strong>,</p>
        <p>La tua prenotazione è stata confermata con successo!</p>
        <div style="background:#fff;border-radius:10px;padding:20px;margin:20px 0;border-left:4px solid #5b7cfa;">
          <h3 style="margin:0 0 16px;color:#333;">${booking.title}</h3>
          <p style="margin:8px 0;color:#555;">🏢 <strong>Risorsa:</strong> ${booking.resource_name}</p>
          <p style="margin:8px 0;color:#555;">📍 <strong>Ubicazione:</strong> ${booking.resource_location || 'Non specificata'}</p>
          <p style="margin:8px 0;color:#555;">📆 <strong>Data:</strong> ${startDate}</p>
          <p style="margin:8px 0;color:#555;">🕐 <strong>Orario:</strong> ${startTime} – ${endTime}</p>
        </div>
<a href="http://localhost:5500?cancel=${booking.id}" style="display:inline-block;margin:8px 0;padding:10px 24px;background:#f87171;color:#fff;border-radius:8px;text-decoration:none;font-weight:600;">Cancella prenotazione</a>        <p style="color:#999;font-size:12px;margin-top:24px;">Se non hai effettuato questa prenotazione contatta l'amministratore.</p>
      </div>
    `,
  });
};
const sendCancellationNotifyEmail = async (email, name, cancelledBooking, cancelledBy) => {
  const startDate = new Date(cancelledBooking.start_time).toLocaleDateString('it-IT', { weekday: 'long', day: '2-digit', month: 'long', year: 'numeric' });
  const startTime = new Date(cancelledBooking.start_time).toLocaleTimeString('it-IT', { hour: '2-digit', minute: '2-digit' });
  const endTime = new Date(cancelledBooking.end_time).toLocaleTimeString('it-IT', { hour: '2-digit', minute: '2-digit' });

  await transporter.sendMail({
    from: `"BookSpace" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: `Aggiornamento disponibilità: ${cancelledBooking.resource_name} — BookSpace`,
    html: `
      <div style="font-family:sans-serif;max-width:500px;margin:0 auto;padding:32px;background:#f9f9f9;border-radius:12px;">
        <h2 style="color:#5b7cfa;">📅 BookSpace</h2>
        <p>Ciao <strong>${name}</strong>,</p>
        <p>Ti informiamo che una prenotazione sulla risorsa che utilizzi è stata <strong style="color:#f87171;">cancellata</strong>.</p>
        <div style="background:#fff;border-radius:10px;padding:20px;margin:20px 0;border-left:4px solid #f87171;">
          <h3 style="margin:0 0 16px;color:#333;">Prenotazione cancellata</h3>
          <p style="margin:8px 0;color:#555;">🏢 <strong>Risorsa:</strong> ${cancelledBooking.resource_name}</p>
          <p style="margin:8px 0;color:#555;">📆 <strong>Data:</strong> ${startDate}</p>
          <p style="margin:8px 0;color:#555;">🕐 <strong>Orario liberato:</strong> ${startTime} – ${endTime}</p>
          <p style="margin:8px 0;color:#555;">👤 <strong>Cancellata da:</strong> ${cancelledBy}</p>
        </div>
        <p>Lo slot potrebbe ora essere disponibile per modificare la tua prenotazione.</p>
        <a href="http://localhost:5500" style="display:inline-block;margin:16px 0;padding:10px 24px;background:#5b7cfa;color:#fff;border-radius:8px;text-decoration:none;font-weight:600;">Vai a BookSpace</a>
        <p style="color:#999;font-size:12px;margin-top:24px;">Questa è una notifica automatica del sistema BookSpace.</p>
      </div>
    `,
  });
};
const sendRecurringBookingConfirmEmail = async (email, name, bookings) => {
  const rows = bookings.map(b => {
    const startDate = new Date(b.start_time).toLocaleDateString('it-IT', { weekday: 'long', day: '2-digit', month: 'long', year: 'numeric' });
    const startTime = new Date(b.start_time).toLocaleTimeString('it-IT', { hour: '2-digit', minute: '2-digit' });
    const endTime = new Date(b.end_time).toLocaleTimeString('it-IT', { hour: '2-digit', minute: '2-digit' });
    return `<tr>
      <td style="padding:8px 12px;border-bottom:1px solid #eee;">📆 ${startDate}</td>
      <td style="padding:8px 12px;border-bottom:1px solid #eee;">🕐 ${startTime} – ${endTime}</td>
    </tr>`;
  }).join('');

  await transporter.sendMail({
    from: `"BookSpace" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: `Prenotazioni ricorrenti confermate: ${bookings[0].title} — BookSpace`,
    html: `
      <div style="font-family:sans-serif;max-width:500px;margin:0 auto;padding:32px;background:#f9f9f9;border-radius:12px;">
        <h2 style="color:#5b7cfa;">📅 BookSpace</h2>
        <p>Ciao <strong>${name}</strong>,</p>
        <p>Le tue prenotazioni ricorrenti sono state confermate!</p>
        <div style="background:#fff;border-radius:10px;padding:20px;margin:20px 0;border-left:4px solid #5b7cfa;">
          <h3 style="margin:0 0 16px;color:#333;">${bookings[0].title}</h3>
          <p style="margin:8px 0;color:#555;">🏢 <strong>Risorsa:</strong> ${bookings[0].resource_name}</p>
          <p style="margin:8px 0;color:#555;">📍 <strong>Ubicazione:</strong> ${bookings[0].resource_location || 'Non specificata'}</p>
          <table style="width:100%;margin-top:16px;border-collapse:collapse;">
            <thead><tr>
              <th style="text-align:left;padding:8px 12px;background:#f5f5f5;font-size:12px;color:#999;">DATA</th>
              <th style="text-align:left;padding:8px 12px;background:#f5f5f5;font-size:12px;color:#999;">ORARIO</th>
            </tr></thead>
            <tbody>${rows}</tbody>
          </table>
        </div>
        <p style="color:#999;font-size:12px;margin-top:24px;">Se non hai effettuato queste prenotazioni contatta l'amministratore.</p>
      </div>
    `,
  });
};
module.exports = { sendResetEmail, sendBookingConfirmEmail, sendCancellationNotifyEmail, sendRecurringBookingConfirmEmail };