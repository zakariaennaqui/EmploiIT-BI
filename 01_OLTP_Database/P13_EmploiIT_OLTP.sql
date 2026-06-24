-- ============================================================
-- PROJET 13 : Offres et Demandes d'Emploi IT
-- Base de données OLTP : DB_EmploiIT
-- Description : Base de données transactionnelle normalisée
--               pour la gestion des offres et candidatures IT.
-- Auteur       : Zakaria Ennaqui — ENSA Berrechid
-- Année        : 2025-2026
-- ============================================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'DB_EmploiIT')
    DROP DATABASE DB_EmploiIT;
GO

CREATE DATABASE DB_EmploiIT;
GO

USE DB_EmploiIT;
GO

-- ============================================================
-- TABLES DE RÉFÉRENCE (Dimensions OLTP)
-- ============================================================

CREATE TABLE Secteurs (
    SecteurID   INT PRIMARY KEY IDENTITY(1,1),
    NomSecteur  VARCHAR(100)
);

CREATE TABLE Entreprises (
    EntrepriseID    INT PRIMARY KEY IDENTITY(1,1),
    NomEntreprise   VARCHAR(150) NOT NULL,
    SecteurID       INT REFERENCES Secteurs(SecteurID),
    Taille          VARCHAR(30),   -- Startup, PME, Grande Entreprise, Multinationale
    Ville           VARCHAR(100)
);

CREATE TABLE Competences (
    CompetenceID    INT PRIMARY KEY IDENTITY(1,1),
    NomComp         VARCHAR(100) NOT NULL,
    Categorie       VARCHAR(50)
);

-- ============================================================
-- TABLES TRANSACTIONNELLES
-- ============================================================

CREATE TABLE Offres (
    OffreID         INT PRIMARY KEY IDENTITY(1,1),
    TitrePoste      VARCHAR(150) NOT NULL,
    EntrepriseID    INT NOT NULL REFERENCES Entreprises(EntrepriseID),
    DatePublication DATE NOT NULL,
    DateExpiration  DATE,
    ContratType     VARCHAR(30),   -- CDI, CDD, Stage, Freelance
    NiveauExp       VARCHAR(30),   -- Débutant, 1-3 ans, 3-5 ans, 5+ ans
    SalaireMin      DECIMAL(8,2),
    SalaireMax      DECIMAL(8,2),
    Ville           VARCHAR(100),
    Remote          BIT DEFAULT 0,
    NbCandidatures  INT DEFAULT 0
);

CREATE TABLE OffresCompetences (
    OffreID         INT NOT NULL REFERENCES Offres(OffreID),
    CompetenceID    INT NOT NULL REFERENCES Competences(CompetenceID),
    PRIMARY KEY (OffreID, CompetenceID)
);

CREATE TABLE Candidats (
    CandidatID          INT PRIMARY KEY IDENTITY(1,1),
    Prenom              VARCHAR(100),
    Nom                 VARCHAR(100),
    Email               VARCHAR(150) UNIQUE NOT NULL,
    NiveauFormation     VARCHAR(50),   -- Bac+3, Bac+5, Bac+8
    Specialisation      VARCHAR(100),
    AnneeExp            INT DEFAULT 0,
    Ville               VARCHAR(100),
    DateInscription     DATE
);

CREATE TABLE CandidatsCompetences (
    CandidatID      INT NOT NULL REFERENCES Candidats(CandidatID),
    CompetenceID    INT NOT NULL REFERENCES Competences(CompetenceID),
    Niveau          VARCHAR(20),   -- Débutant, Intermédiaire, Avancé, Expert
    PRIMARY KEY (CandidatID, CompetenceID)
);

CREATE TABLE Candidatures (
    CandidatureID   INT PRIMARY KEY IDENTITY(1,1),
    CandidatID      INT NOT NULL REFERENCES Candidats(CandidatID),
    OffreID         INT NOT NULL REFERENCES Offres(OffreID),
    DateCandidature DATE NOT NULL,
    Statut          VARCHAR(30) DEFAULT 'Reçue',  -- Reçue, Entretien, Rejetée, Embauchée
    DateEntretien   DATE,
    Notes           TEXT
);

-- ============================================================
-- DONNÉES DE TEST
-- ============================================================

INSERT INTO Secteurs VALUES
    ('Banque & Finance'),
    ('Télécommunications'),
    ('E-Commerce & Retail'),
    ('Industrie & Manufacturing'),
    ('Conseil IT'),
    ('Santé & Pharma'),
    ('Éducation');

INSERT INTO Entreprises VALUES
    ('CIH Bank',            1, 'Grande Entreprise', 'Casablanca'),
    ('Maroc Telecom',       2, 'Grande Entreprise', 'Rabat'),
    ('Jumia Maroc',         3, 'Startup',           'Casablanca'),
    ('OCP Group',           4, 'Grande Entreprise', 'Casablanca'),
    ('Capgemini Maroc',     5, 'Multinationale',    'Casablanca'),
    ('BMCI',                1, 'Grande Entreprise', 'Casablanca'),
    ('inwi',                2, 'Grande Entreprise', 'Casablanca'),
    ('Société Générale Maroc', 1, 'Multinationale', 'Casablanca');

INSERT INTO Competences VALUES
    ('Python',          'Programmation'),
    ('SQL',             'Bases de données'),
    ('Power BI',        'Business Intelligence'),
    ('Java',            'Programmation'),
    ('React',           'Développement Web'),
    ('Machine Learning','IA'),
    ('DevOps / Docker', 'Infrastructure'),
    ('Azure',           'Cloud'),
    ('Cybersécurité',   'Sécurité'),
    ('C#',              'Programmation'),
    ('SSIS / ETL',      'Business Intelligence'),
    ('Tableau',         'Business Intelligence');

INSERT INTO Offres VALUES
    ('Data Engineer',               1, '2024-01-10', '2024-02-10', 'CDI',   '3-5 ans',   15000, 22000, 'Casablanca', 0, 45),
    ('Data Scientist',              5, '2024-01-15', '2024-02-15', 'CDI',   '1-3 ans',   12000, 18000, 'Casablanca', 1, 62),
    ('Développeur Full Stack React/Node', 3, '2024-02-01', '2024-03-01', 'CDI', '1-3 ans', 10000, 15000, 'Casablanca', 1, 38),
    ('Analyste BI Power BI',        6, '2024-02-10', '2024-03-10', 'CDI',   '1-3 ans',   11000, 16000, 'Casablanca', 0, 29),
    ('Ingénieur Cybersécurité',     2, '2024-03-01', '2024-04-01', 'CDI',   '3-5 ans',   18000, 26000, 'Rabat',      0, 25),
    ('Développeur .NET C#',         1, '2024-03-15', '2024-04-15', 'CDI',   '3-5 ans',   13000, 19000, 'Casablanca', 0, 33),
    ('Stage Data Analyst',          4, '2024-04-01', '2024-05-01', 'Stage', 'Débutant',   4000,  6000, 'Casablanca', 0, 85),
    ('Cloud Architect Azure',       8, '2024-04-15', '2024-05-15', 'CDI',   '5+ ans',    22000, 35000, 'Casablanca', 1, 18);

-- Liaison Offres ↔ Compétences
INSERT INTO OffresCompetences VALUES
    (1,2),(1,1),(1,11),(1,8),
    (2,1),(2,6),(2,8),
    (3,5),(3,4),
    (4,3),(4,2),(4,11),
    (5,9),
    (6,10),(6,2),
    (7,3),(7,2),
    (8,8),(8,7);

INSERT INTO Candidats VALUES
    ('Mohamed', 'Alaoui',    'm.alaoui@gmail.com',   'Bac+5', 'Génie Informatique',      2, 'Casablanca', '2023-11-10'),
    ('Sara',    'Tahiri',    's.tahiri@gmail.com',   'Bac+5', 'Data Science',            1, 'Rabat',      '2024-01-05'),
    ('Amine',   'Benali',    'a.benali@gmail.com',   'Bac+3', 'Développement Web',       3, 'Casablanca', '2023-09-20'),
    ('Fatima',  'El Fassi',  'f.elfassi@gmail.com',  'Bac+5', 'Business Intelligence',   2, 'Casablanca', '2024-01-15'),
    ('Youssef', 'Bakkali',   'y.bakkali@gmail.com',  'Bac+5', 'Cybersécurité',           4, 'Rabat',      '2023-07-12'),
    ('Nadia',   'Berrada',   'n.berrada@gmail.com',  'Bac+8', 'IA & Machine Learning',   1, 'Casablanca', '2024-02-01'),
    ('Hamza',   'Tazi',      'h.tazi@gmail.com',     'Bac+5', 'DevOps / Cloud',          3, 'Casablanca', '2023-10-08');

-- Liaison Candidats ↔ Compétences
INSERT INTO CandidatsCompetences VALUES
    (1,1,'Intermédiaire'),(1,2,'Avancé'),(1,11,'Intermédiaire'),
    (2,1,'Avancé'),(2,6,'Avancé'),(2,3,'Intermédiaire'),
    (3,5,'Avancé'),(3,4,'Intermédiaire'),
    (4,3,'Avancé'),(4,2,'Avancé'),(4,11,'Avancé'),
    (5,9,'Avancé'),
    (6,1,'Expert'),(6,6,'Expert'),
    (7,7,'Avancé'),(7,8,'Intermédiaire');

INSERT INTO Candidatures VALUES
    (1, 1, '2024-01-12', 'Entretien',  '2024-01-25', NULL),
    (1, 4, '2024-02-12', 'Reçue',      NULL,          NULL),
    (2, 2, '2024-01-18', 'Embauchée',  '2024-01-28', 'Excellente candidate'),
    (2, 7, '2024-04-05', 'Reçue',      NULL,          NULL),
    (3, 3, '2024-02-05', 'Entretien',  '2024-02-15', NULL),
    (4, 4, '2024-02-15', 'Embauchée',  '2024-02-20', 'Profil idéal'),
    (4, 1, '2024-01-15', 'Rejetée',    NULL,          'Profil insuffisant'),
    (5, 5, '2024-03-05', 'Entretien',  '2024-03-15', NULL),
    (6, 2, '2024-01-20', 'Reçue',      NULL,          NULL),
    (7, 8, '2024-04-20', 'Reçue',      NULL,          NULL),
    (3, 7, '2024-04-08', 'Entretien',  '2024-04-20', NULL);

GO

PRINT 'DB_EmploiIT créée et peuplée avec succès.';
GO
