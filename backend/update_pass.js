const {Pool}=require('pg');
const bcrypt=require('bcrypt');
const pool=new Pool({connectionString:'postgresql://postgres:postgres123@localhost:5432/booking_interno'});
bcrypt.hash('password123',10).then(h=>{
  pool.query('UPDATE users SET password=' + '$' + '1',[h]).then(()=>{
    console.log('Password aggiornata!');
    pool.end();
  });
});
