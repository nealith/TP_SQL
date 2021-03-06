ALTER TABLE Agence
	DROP CONSTRAINT fkDirecteur;

DROP TABLE Appartient;

DROP TABLE Operation;

DROP TABLE Compte;

DROP TABLE TypeCompte;

DROP TABLE Client;

DROP TABLE Agent;

DROP TABLE Agence;

CREATE TABLE TypeCompte (

	numTypeCompte NUMBER(1)
	CONSTRAINT pkTypeCompte
	PRIMARY KEY,

	libTypeCompte VARCHAR2(15)
	CONSTRAINT ckLibTypeCompte
	CHECK (UPPER(libTypeCompte) LIKE 'COMPTE COURANT' OR UPPER(libTypeCompte) LIKE 'COMPTE EPARGNE')

);


CREATE TABLE Compte (

	numCompte NUMBER(5)
	CONSTRAINT pkCompte
	PRIMARY KEY,

	solde NUMBER(38),

	typeCompte NUMBER(1)
	CONSTRAINT fkTypeCompte
	REFERENCES TypeCompte(numTypeCompte)

);	

CREATE TABLE Agence (

	numAgence NUMBER(5)
	CONSTRAINT pkAgence
	PRIMARY KEY,

	telAgence VARCHAR2(15),

	directeur NUMBER(5)

);

CREATE TABLE Agent (

	numAgent NUMBER(5)
	CONSTRAINT pkAgent
	PRIMARY KEY,

	nomAgent VARCHAR2(15),

	prenomAgent VARCHAR2(15),

	adresse VARCHAR2(15),

	salaire NUMBER(10)
	CONSTRAINT ckSalaire
	CHECK (salaire > 1000),

	agence NUMBER(5)
	CONSTRAINT fkAgence
	REFERENCES Agence(numAgence)

);

ALTER TABLE Agence
	ADD CONSTRAINT fkDirecteur
		FOREIGN KEY (Directeur)
		REFERENCES Agent(numAgent);


CREATE TABLE Client (

	numClient NUMBER(5)
	CONSTRAINT pkClient
	PRIMARY KEY,

	nomClient VARCHAR2(15)
	CONSTRAINT nnClientNom
	NOT NULL,

	prenomClient VARCHAR2(15)
	CONSTRAINT nnClientPrenom
	NOT NULL,

	adresse VARCHAR2(15),

	agent NUMBER(5)
	CONSTRAINT fkAgent
	REFERENCES Agent(numAgent)
);

CREATE TABLE Appartient (

	numClient NUMBER(5)
	CONSTRAINT fkClientA
	REFERENCES Client(numClient),

	numCompte NUMBER(5)
	CONSTRAINT fkCompteA
	REFERENCES Compte(numCompte),	

	CONSTRAINT pkAppartient
	PRIMARY KEY (numClient,numCompte)

);

CREATE TABLE Operation (

	numOperation NUMBER(5)
	CONSTRAINT pkOperation
	PRIMARY KEY,

	numClient NUMBER(5)
	CONSTRAINT fkClientO
	REFERENCES Client(numClient),

	numCompte NUMBER(5)
	CONSTRAINT fkCompteO
	REFERENCES Compte(numCompte),	

	dateOperation VARCHAR2(8),

	montant NUMBER(38)
	CONSTRAINT ckMontant
	CHECK (montant > 0),

	typeOperation VARCHAR2(15)
	CONSTRAINT ckTypeOperation
	CHECK (UPPER(typeOperation) LIKE 'RETRAIT' OR UPPER(typeOperation) LIKE 'CREDIT')	

);			

CREATE OR REPLACE TRIGGER SafeRetrait
BEFORE INSERT OR UPDATE ON Operation
FOR EACH ROW 
WHEN (UPPER (new.typeOperation) = 'RETRAIT')
DECLARE
	s NUMBER;

BEGIN 
	SELECT solde INTO s
	FROM Compte
	WHERE Compte.numCompte = :new.numCompte;
	IF (:new.montant > s)THEN
		RAISE_APPLICATION_ERROR(-2001,'Solde insufisant');
	END IF;
END;	
/

CREATE OR REPLACE TRIGGER RetraitBon
BEFORE INSERT OR UPDATE ON Operation
FOR EACH ROW
WHEN (UPPER (new.typeOperation) = 'RETRAIT')
DECLARE 
	row Appartient.numClient%TYPE;
	CURSOR tmpCpt IS 
		SELECT numClient
		FROM Appartient
		WHERE :new.numCompte = Appartient.numCompte
		AND :new.numClient = Appartient.numClient; 

BEGIN 
	OPEN tmpCpt;
	FETCH tmpCpt INTO row;
	IF (tmpCpt%NOTFOUND) THEN
		CLOSE tmpCpt;
		RAISE_APPLICATION_ERROR(-20072,'erreur sac à merde');
	END IF;
	CLOSE tmpCpt;	
END;
/

CREATE OR REPLACE TRIGGER theBossAgent
BEFORE INSERT OR UPDATE OF salaire ON Agent
FOR EACH ROW 
DECLARE 
	salaireMax NUMBER;
	estBoss BOOLEAN;
	salaireBoss NUMBER;
	var Agent.numAgent%TYPE;
	CURSOR tmpBoss IS 
		SELECT DISTINCT Directeur
		FROM Agence
		WHERE :new.numAgent = Directeur;

BEGIN

		OPEN tmpBoss;
		FETCH tmpBoss INTO var;
		estBoss := tmpBoss%FOUND;
		CLOSE tmpBoss;

		IF (estBoss) THEN
			SELECT MAX(Salaire) INTO salaireMax
			FROM Agent , Agence
			WHERE Directeur != :new.NumAgent
			AND Agent.agence = Agence.numAgence;

			IF (:new.Salaire <= salaireMax) THEN
				RAISE_APPLICATION_ERROR(-20046,'Sous merde, apprends à coder');
			END IF;
		ELSE
			SELECT Salaire INTO salaireBoss
			FROM Agence, Agent
			WHERE :new.agence = Agence.numAgence
			AND Agent.agence = Agence.numAgence
			AND Directeur = numAgent;
			IF ( :new.salaire >= salaireBoss) THEN
				RAISE_APPLICATION_ERROR(-20047,'Ta mère hier soir, a gagné plus que lui, grâce à moi');
			END IF;
			
		END IF;		

END;				
/

CREATE OR REPLACE TRIGGER theBossAgence
BEFORE INSERT OR UPDATE OF Directeur ON Agence
FOR EACH ROW
DECLARE 
	salaireMax NUMBER;
	salaireBoss NUMBER;
BEGIN
		SELECT MAX(Salaire) INTO salaireMax
		FROM Agent , Agence
		WHERE Agent.numAgent != :new.Directeur
		AND Agent.agence = :new.numAgence;
		SELECT salaire INTO salaireBoss
		FROM Agent , Agence
		WHERE :new.directeur = agent.numAgent;
		IF (salaireBoss <= salaireMax) THEN
			RAISE_APPLICATION_ERROR(-20048,'Rappel directeur = boss , pas esclave ');
		END IF;
END;
/

SET AUTOCOMMIT OFF;

CREATE OR REPLACE PROCEDURE transfer(numOperation NUMBER, idCompteD NUMBER, idCompteC NUMBER, montant NUMBER, client NUMBER, dateOperation VARCHAR2)
IS
BEGIN
	SET TRANSACTION; 
	LOCK TABLE Compte IN SHAREMODE;
	UPDATE Compte
	SET solde = (solde - montant)
	WHERE numCompte = idCompteD;
	UPDATE Compte
	SET solde = (solde + montant)
	WHERE numCompte = idCompteC;

	LOCK TABLE Operation IN SHAREMODE;
	INSERT INTO Operation (numOperation, numCompte, numClient, type, montant, dateOperation)
	VALUE (numOperation, idCompteD , client , 'RETRAIT' , montant , dateOperation);
	INSERT INTO Operation (numOperation, numCompte, numClient, type, montant, dateOperation)
	VALUE (numOperation, idCompteC , client , 'CREDIT' , montant , dateOperation);	

	COMMIT;

	EXCEPTION 
		WHEN DATANOTFOUND THEN
			ROLLBACK;
			DBMS OUTPUT.PUT.LINE('mirde....')
		WHEN OTHER THEN
			ROLLBACK;
END;
/				


SHOW ERRORS;