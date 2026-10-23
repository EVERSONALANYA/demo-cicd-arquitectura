const { app } = require('./app');

// Twelve-Factor: el puerto viene de la variable de entorno PORT (Render la asigna)
const port = process.env.PORT || 3000;

app.listen(port, () => {
  console.log(`Servidor escuchando en el puerto ${port}`);
});
