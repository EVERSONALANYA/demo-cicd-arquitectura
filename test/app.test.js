import { describe, it, expect } from 'vitest';
import request from 'supertest';
import appModule from '../src/app';
import pkg from '../package.json';

const { app, porcentajeAsistencia } = appModule;
const { version } = pkg;

describe('Endpoint /health', () => {
  it('responde 200 con estado healthy y la versión actual', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('healthy');
    expect(res.body.version).toBe(version);
  });
});

describe('porcentajeAsistencia', () => {
  it('calcula el porcentaje de asistencia', () => {
    expect(porcentajeAsistencia(18, 20)).toBe(90);
  });

  it('devuelve 0 si no hay clases registradas', () => {
    expect(porcentajeAsistencia(0, 0)).toBe(0);
  });
});
