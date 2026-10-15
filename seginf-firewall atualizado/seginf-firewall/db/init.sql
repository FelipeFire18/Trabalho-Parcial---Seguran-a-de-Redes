CREATE TABLE IF NOT EXISTS alunos (
  id SERIAL PRIMARY KEY,
  nome TEXT NOT NULL,
  matricula TEXT UNIQUE NOT NULL
);
INSERT INTO alunos (nome, matricula) VALUES
  ('Aluno Exemplo 1', '2026001'),
  ('Aluno Exemplo 2', '2026002')
ON CONFLICT DO NOTHING;
