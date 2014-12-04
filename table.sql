DROP TABLE TypeCompte;

DROP TABLE Compte;

DROP TABLE Agence;

DROP TABLE Agent;

DROP TABLE Client;

DROP TABLE Appartient;

DROP TABLE Operation;

CREATE TABLE TypeCompte (

	numTypeCompte NUMBER(1)
	CONSTRAINT pkTypeCompte
	PRIMARY KEY,

	libTypeCompte VARCHAR2(15)
	CONSTRAINT ckLibTypeCompte
	CHECK (UPPER(libTypeCompte LIKE 'COMPTE COURANT') OR UPPER(libTypeCompte LIKE 'COMPTE EPARGNE')),

);


CREATE TABLE Compte (

	numCompte NUMBER(5)
	CONSTRAINT pkCompte
	PRIMARY KEY,

	solde NUMBER(38),

	typeCompte NUMBER(1)
	CONSTRAINT fkTypeCompte
	FOREIGN KEY TypeCompte(numTypeCompte),

);	

CREATE TABLE Agence (

	numAgence NUMBER(5)
	CONSTRAINT pkAgence
	PRIMARY KEY,

	telAgence VARCHAR2(15),

	directeur NUMBER(5),

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
	FOREIGN KEY Agence(numAgence),

);

ALTER TABLE Agence
	ADD CONSTRAINT fkDirecteur
		FOREIGN KEY (Directeur)
		REFERENCES Agent(numAgent);


CREATE TABLE Client (

	numClient NUMBER(5)
	CONSTRAINT pkAgent
	PRIMARY KEY,

	nomClient VARCHAR2(15)
	CONSTRAINT nnNom
	NOT NULL,

	prenomClient VARCHAR2(15)
	CONSTRAINT nnPrenom
	NOT NULL,

	adresse VARCHAR2(15),

	agence NUMBER(5)
	CONSTRAINT fkAgence
	FOREIGN KEY Agence(numAgence),

	agent NUMBER(5)
	CONSTRAINT fkAgent
	FOREIGN KEY Agent(numAgent),
);

CREATE TABLE Appartient (

	numClient NUMBER(5),	
	numCompte NUMBER(5),

	CONSTRAINT pkAppartient
	PRIMARY KEY (numClient,numCompte),

);

CREATE TABLE Operation (

	numOperation NUMBER(5)
	CONSTRAINT pkOperation
	PRIMARY KEY,

	numClient NUMBER(5)
	CONSTRAINT fkClient
	FOREIGN KEY Client(numClient),

	numCompte NUMBER(5)
	CONSTRAINT fkCompte
	FOREIGN KEY Compte(numCompte),	

	dateOperation VARCHAR2(8),

	montant NUMBER(38)
	CONSTRAINT ckMontant
	CHECK (montant > 0),

);			