-- ============================================================
-- PROJET 13 : Offres et Demandes d'Emploi IT
-- Script de chargement manuel du Data Warehouse DW_EmploiIT
-- Description : Équivalent T-SQL des packages SSIS.
--               Peuple les dimensions puis les tables de faits.
-- ============================================================

USE DW_EmploiIT;
GO

-- ============================================================
-- ÉTAPE 0 : Vider le DW (ordre respecté pour les FK)
-- ============================================================
TRUNCATE TABLE FactCandidatures;
TRUNCATE TABLE FactOffres;
DELETE FROM DimOffre;
DELETE FROM DimCandidat;
DELETE FROM DimCompetence;
DELETE FROM DimEntreprise;
DELETE FROM DimVille;
DELETE FROM DimSecteur;
DELETE FROM DimContrat;
DELETE FROM DimTemps;
GO

-- ============================================================
-- ÉTAPE 1 : Charger DimTemps
-- ============================================================
DECLARE @d DATE = '2023-01-01';
WHILE @d <= '2025-12-31'
BEGIN
    INSERT INTO DimTemps (DateComplete, Jour, Mois, Trimestre, Annee, NomMois, NomJourSemaine, EstWeekend)
    VALUES (
        @d,
        DAY(@d),
        MONTH(@d),
        DATEPART(QUARTER, @d),
        YEAR(@d),
        DATENAME(MONTH, @d),
        DATENAME(WEEKDAY, @d),
        CASE WHEN DATEPART(WEEKDAY, @d) IN (1,7) THEN 1 ELSE 0 END
    );
    SET @d = DATEADD(DAY, 1, @d);
END;
GO

-- ============================================================
-- ÉTAPE 2 : Charger DimEntreprise
-- ============================================================
INSERT INTO DimEntreprise (EntrepriseID, NomEntreprise, NomSecteur, Taille, Ville)
SELECT
    e.EntrepriseID,
    e.NomEntreprise,
    s.NomSecteur,
    e.Taille,
    e.Ville
FROM DB_EmploiIT.dbo.Entreprises e
JOIN DB_EmploiIT.dbo.Secteurs s ON e.SecteurID = s.SecteurID;
GO

-- ============================================================
-- ÉTAPE 3 : Charger DimCandidat
-- ============================================================
INSERT INTO DimCandidat (CandidatID, Prenom, Nom, NiveauFormation, Specialisation, AnneeExp, Ville)
SELECT
    CandidatID,
    Prenom,
    Nom,
    NiveauFormation,
    Specialisation,
    AnneeExp,
    Ville
FROM DB_EmploiIT.dbo.Candidats;
GO

-- ============================================================
-- ÉTAPE 4 : Charger DimCompetence
-- ============================================================
INSERT INTO DimCompetence (CompetenceID, NomComp, Categorie)
SELECT CompetenceID, NomComp, Categorie
FROM DB_EmploiIT.dbo.Competences;
GO

-- ============================================================
-- ÉTAPE 5 : Charger DimOffre
-- ============================================================
INSERT INTO DimOffre (OffreID, TitrePoste, ContratType, NiveauExp, Remote, Ville, EntrepriseSK)
SELECT
    o.OffreID,
    o.TitrePoste,
    o.ContratType,
    o.NiveauExp,
    o.Remote,
    o.Ville,
    de.EntrepriseSK
FROM DB_EmploiIT.dbo.Offres o
JOIN DimEntreprise de ON de.EntrepriseID = o.EntrepriseID;
GO

-- ============================================================
-- ÉTAPE 6 : Charger FactOffres (une ligne par offre × compétence)
-- ============================================================
INSERT INTO FactOffres (OffreSK, OffreID_NK, EntrepriseSK, CompetenceSK,
                        DatePublicationSK, DateExpirationSK,
                        SalaireMin, SalaireMax, NbCandidatures, DureeOffre_Jours)
SELECT
    dof.OffreSK,
    o.OffreID,
    dof.EntrepriseSK,
    dc.CompetenceSK,
    tp.TempsID     AS DatePublicationSK,
    te.TempsID     AS DateExpirationSK,
    o.SalaireMin,
    o.SalaireMax,
    o.NbCandidatures,
    DATEDIFF(DAY, o.DatePublication, ISNULL(o.DateExpiration, o.DatePublication)) AS DureeOffre_Jours
FROM DB_EmploiIT.dbo.Offres o
JOIN DB_EmploiIT.dbo.OffresCompetences oc ON o.OffreID = oc.OffreID
JOIN DimOffre dof       ON dof.OffreID     = o.OffreID
JOIN DimCompetence dc   ON dc.CompetenceID = oc.CompetenceID
JOIN DimEntreprise de   ON de.EntrepriseID = o.EntrepriseID
JOIN DimTemps tp        ON tp.DateComplete  = o.DatePublication
LEFT JOIN DimTemps te   ON te.DateComplete  = o.DateExpiration;
GO

-- ============================================================
-- ÉTAPE 7 : Charger FactCandidatures
-- ============================================================
INSERT INTO FactCandidatures (CandidatureID_NK, CandidatSK, OffreSK,
                              DateCandidatureSK, DateEntretienSK,
                              EstEmbauche, DelaiEntretien_Jours, NbCompetencesMatch)
SELECT
    can.CandidatureID,
    dc.CandidatSK,
    dof.OffreSK,
    tc.TempsID     AS DateCandidatureSK,
    te.TempsID     AS DateEntretienSK,
    CASE WHEN can.Statut = 'Embauchée' THEN 1 ELSE 0 END AS EstEmbauche,
    CASE WHEN can.DateEntretien IS NOT NULL
         THEN DATEDIFF(DAY, can.DateCandidature, can.DateEntretien)
         ELSE NULL END AS DelaiEntretien_Jours,
    (
        SELECT COUNT(*)
        FROM DB_EmploiIT.dbo.CandidatsCompetences cc1
        JOIN DB_EmploiIT.dbo.OffresCompetences oc1 ON cc1.CompetenceID = oc1.CompetenceID
        WHERE cc1.CandidatID = can.CandidatID AND oc1.OffreID = can.OffreID
    ) AS NbCompetencesMatch
FROM DB_EmploiIT.dbo.Candidatures can
JOIN DimCandidat dc  ON dc.CandidatID = can.CandidatID
JOIN DimOffre dof    ON dof.OffreID   = can.OffreID
JOIN DimTemps tc     ON tc.DateComplete = can.DateCandidature
LEFT JOIN DimTemps te ON te.DateComplete = can.DateEntretien;
GO

PRINT 'Chargement du DW_EmploiIT terminé avec succès.';
GO
