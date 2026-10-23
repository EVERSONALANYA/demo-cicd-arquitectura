const express = require('express');
const { version } = require('../package.json');

const app = express();

// Página principal: el texto visible que cambia en la demo (v1.0.0 -> v1.1.0)
app.get('/', (req, res) => {
  res.send(`
    <main style="font-family: sans-serif; text-align: center; margin-top: 15vh">
      <h1>Sistema de Asistencia QR</h1>
      <p style="font-size: 2rem">Versión ${version}</p>
    </main>
  `);
});

// Health check: lo usa el pipeline (y Render) para saber si la versión nueva está sana
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    version,
    commit: process.env.GIT_SHA || 'local',
  });
});

// Función de negocio con pruebas unitarias (la que se rompe en el escenario 2)
function porcentajeAsistencia(presentes, total) {
  if (total <= 0) return 0;
  return Math.round((presentes / total) * 100);
}

module.exports = { app, porcentajeAsistencia };
