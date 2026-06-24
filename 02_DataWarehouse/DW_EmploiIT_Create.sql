-- ============================================================
-- PROJET 13 : Offres et Demandes d'Emploi IT
-- Data Warehouse : DW_EmploiIT — Schéma en Étoile
-- Description : Entrepôt de données décisionnel pour
--               l'analyse du marché de l'emploi IT au Maroc.
-- ============================================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'DW_EmploiIT')
    DROP DATABASE DW_EmploiIT;
GO

CREATE DATABASE DW_EmploiIT;
GO

USE DW_EmploiIT;
GO

-- ============================================================
-- TABLES DE DIMENSIONS
-- ============================================================

-- Dimension Temps
CREATE TABLE DimTemps (
    TempsID         INT PRIMARY KEY IDENTITY(1,1),
    DateComplete    DATE NOT NULL,
    Jour            INT,
    Mois            INT,
    Trimestre       INT,
    Annee           INT,
    NomMois         VARCHAR(20),
    NomJourSemaine  VARCHAR(20),
    EstWeekend      BIT DEFAULT 0
);

-- Dimension Entreprise
CREATE TABLE DimEntreprise (
    EntrepriseSK    INT PRIMARY KEY IDENTITY(1,1),
    EntrepriseID    INT NOT NULL,   -- Clé naturelle (NK) depuis OLTP
    NomEntreprise   VARCHAR(150),
    NomSecteur      VARCHAR(100),
    Taille          VARCHAR(30),
    Ville           VARCHAR(100)
);

-- Dimension Candidat
CREATE TABLE DimCandidat (
    CandidatSK      INT PRIMARY KEY IDENTITY(1,1),
    CandidatID      INT NOT NULL,   -- Clé naturelle (NK) depuis OLTP
    Prenom          VARCHAR(100),
    Nom             VARCHAR(100),
    NiveauFormation VARCHAR(50),
    Specialisation  VARCHAR(100),
    AnneeExp        INT,
    Ville           VARCHAR(100)
);

-- Dimension Compétence
CREATE TABLE DimCompetence (
    CompetenceSK    INT PRIMARY KEY IDENTITY(1,1),
    CompetenceID    INT NOT NULL,   -- Clé naturelle (NK) depuis OLTP
    NomComp         VARCHAR(100),
    Categorie       VARCHAR(50)
);

-- Dimension Offre
CREATE TABLE DimOffre (
    OffreSK         INT PRIMARY KEY IDENTITY(1,1),
    OffreID         INT NOT NULL,   -- Clé naturelle (NK) depuis OLTP
    TitrePoste      VARCHAR(150),
    ContratType     VARCHAR(30),
    NiveauExp       VARCHAR(30),
    Remote          BIT,
    Ville           VARCHAR(100),
    EntrepriseSK    INT REFERENCES DimEntreprise(EntrepriseSK)
);

-- Dimension Ville
CREATE TABLE DimVille (
    VilleSK         INT PRIMARY KEY IDENTITY(1,1),
    VilleID         INT NOT NULL,
    NomVille        VARCHAR(100),
    Pays            VARCHAR(100) DEFAULT 'Maroc'
);

-- Dimension Secteur
CREATE TABLE DimSecteur (
    SecteurSK       INT PRIMARY KEY IDENTITY(1,1),
    SecteurID       INT NOT NULL,
    NomSecteur      VARCHAR(100)
);

-- Dimension Contrat
CREATE TABLE DimContrat (
    ContratSK       INT PRIMARY KEY IDENTITY(1,1),
    ContratID       INT NOT NULL,
    TypeContrat     VARCHAR(30)
);

-- ============================================================
-- TABLES DE FAITS
-- ============================================================

-- Fait : Offres publiées (une ligne par offre × compétence)
CREATE TABLE FactOffres (
    FactOffreSK         INT PRIMARY KEY IDENTITY(1,1),
    OffreSK             INT NOT NULL REFERENCES DimOffre(OffreSK),
    OffreID_NK          INT,
    EntrepriseSK        INT NOT NULL REFERENCES DimEntreprise(EntrepriseSK),
    CompetenceSK        INT NOT NULL REFERENCES DimCompetence(CompetenceSK),
    DatePublicationSK   INT NOT NULL REFERENCES DimTemps(TempsID),
    DateExpirationSK    INT REFERENCES DimTemps(TempsID),
    SalaireMin          DECIMAL(8,2),
    SalaireMax          DECIMAL(8,2),
    NbCandidatures      INT,
    DureeOffre_Jours    INT
);

-- Fait : Candidatures soumises
CREATE TABLE FactCandidatures (
    FactCandidatureSK   INT PRIMARY KEY IDENTITY(1,1),
    CandidatureID_NK    INT,
    CandidatSK          INT NOT NULL REFERENCES DimCandidat(CandidatSK),
    OffreSK             INT NOT NULL REFERENCES DimOffre(OffreSK),
    CompetenceSK        INT REFERENCES DimCompetence(CompetenceSK),
    DateCandidatureSK   INT NOT NULL REFERENCES DimTemps(TempsID),
    DateEntretienSK     INT REFERENCES DimTemps(TempsID),
    EstEmbauche         BIT DEFAULT 0,
    DelaiEntretien_Jours INT,
    NbCompetencesMatch  INT
);

GO

PRINT 'DW_EmploiIT (schéma en étoile) créé avec succès.';
GO
