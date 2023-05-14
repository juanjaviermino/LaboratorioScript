/*
El siguiente script fue desarrollado por el grupo 8J de la clase: ITIZ-2201 - BASE DE DATOS II – 3180 - 202302
La base de datos creada en este script será utilizada para los procesos internos de un laboratorio de análisis de suelos y aguas

Autores: Iván Tulcán, Washington Yandún, y Juan Javier Miño.
Fecha de creacion: 08-05-2023 07:34
Última versión: 10-05-2023 18:38
*/

/********************************** Uso de la base de datos Master y deshabilitación del usuario sa ************************************************/

/*Utilizar la master para crear la base de datos laboratorio*/
USE master
GO

/************************************************* Proceso de habilitación de autenticación mixta **************************************************/

/* Habilitar el modo de autenticación mixta */
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2
GO

/*Activación del shell de la base de datos*/
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;

/*Habilitación del protocolo Named Pipes*/
EXEC sp_configure 'remote access', 1;
RECONFIGURE;
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer\SuperSocketNetLib\Np', N'Enabled', REG_DWORD, 1;

/*Habilitación del protocolo TCP/IP*/
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer\SuperSocketNetLib\Tcp', N'Enabled', REG_DWORD, 1;
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer\SuperSocketNetLib\Tcp\IPAll', N'TcpPort', REG_SZ, N'1433';
GO

/*ALERTA para indicar que el servidor se reiniciará*/
RAISERROR('El servidor se reiniciará para efectuar los cambios en la autenticación mixta', 0, 1) WITH NOWAIT
GO

/*Reinicio del servidor para efectuar cambios*/
EXEC xp_cmdshell 'NET STOP MSSQLSERVER'
GO
EXEC xp_cmdshell 'NET START MSSQLSERVER'
GO

/******************************************* Creación de la base de datos *************************************************/

/*Comprobar la existencia de Laboratorio para eliminar la base, si existe*/
IF EXISTS(SELECT name FROM sys.databases WHERE name = 'Laboratorio')
BEGIN
    DROP DATABASE Laboratorio;
END

/*Crear la base de datos llamada Laboratorio*/
CREATE DATABASE Laboratorio
GO

/*Utilizar la base de datos Laboratorio*/
USE Laboratorio
GO

/****************************************** Segunda consideración de ciberseguridad: encriptación de datos sensibles *******************************************************/

/*Creación de una llave maestra*/
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'SQLShack@1';
GO

/*Creación de un certificado*/
CREATE CERTIFICATE Certificate_test WITH SUBJECT = 'Proteger datos sensibles';
GO

/*Creación de una llave simétrica para la encriptación*/
CREATE SYMMETRIC KEY SymKey_test WITH ALGORITHM = AES_256 ENCRYPTION BY CERTIFICATE Certificate_test;
GO

/*Abrir la llave simétrica*/
OPEN SYMMETRIC KEY SymKey_test
DECRYPTION BY CERTIFICATE Certificate_test;
GO

/***************************************** Creación de logins ****************************************************************************************/

/*Verificación de existencia del login Gerente*/
IF EXISTS (SELECT * FROM sys.syslogins WHERE loginname = 'Gerente')
BEGIN
    DROP LOGIN [Gerente]
END
/*Crear login: Gerente*/
CREATE LOGIN [Gerente] WITH PASSWORD=N'GerenciaGeneral!@#2023' MUST_CHANGE, DEFAULT_DATABASE=[Laboratorio], CHECK_EXPIRATION=ON, CHECK_POLICY=ON
GO


/*Verificación de existencia del login Personal*/
IF EXISTS (SELECT * FROM sys.syslogins WHERE loginname = 'Personal')
BEGIN
    DROP LOGIN [Personal]
END
/*Crear login: Personal*/
CREATE LOGIN [Personal] WITH PASSWORD=N'PersonalLab#$' MUST_CHANGE, DEFAULT_DATABASE=[Laboratorio], CHECK_EXPIRATION=ON, CHECK_POLICY=ON
GO


/*Verificación de existencia del login Administrador*/
IF EXISTS (SELECT * FROM sys.syslogins WHERE loginname = 'Administrador')
BEGIN
    DROP LOGIN [Administrador]
END
/*Crear login (nuevo administrador)*/
CREATE LOGIN [Administrador] WITH PASSWORD=N'AdminLab!@2023' MUST_CHANGE, DEFAULT_DATABASE=[Laboratorio], CHECK_EXPIRATION=ON, CHECK_POLICY=ON
GO
ALTER SERVER ROLE sysadmin ADD MEMBER [Administrador]; 
GO

/******************************************** Creación de usuarios *********************************************************************/

/*Verificación de existencia del usuario Gerente General*/
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'GerenteGeneral' AND type_desc = 'SQL_USER')
BEGIN
    DROP USER [GerenteGeneral]
END
/*Crear el usuario Gerente General: SELECT, INSERTS, UPDATES, DELETES: en qué tablas. NO PUEDE ELIMINAR ENSAYOS.*/
CREATE USER [GerenteGeneral] FOR LOGIN [Gerente]
GO


/*Verificación de existencia del usuario Personal Lab*/
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'PersonalLab' AND type_desc = 'SQL_USER')
BEGIN
    DROP USER [PersonalLab]
END
/*Crear el usuario Personal Lab: SELECT, INSERTS, UPDATES, DELETES: en qué tablas. NO PUEDE ELIMINAR ENSAYOS.*/
CREATE USER [PersonalLab] FOR LOGIN [Personal]
GO


/*Verificación de existencia del usuario AdministradorLab*/
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'AdministradorLab' AND type_desc = 'SQL_USER')
BEGIN
    DROP USER [AdministradorLab]
END
/*Crear el usuario Administrador Lab: Para los técnicos de la base de datos: Todos los permisos.*/
CREATE USER [AdministradorLab] FOR LOGIN [Administrador]
GO

/************************************************* Manejo de errores **************************************************/

/*Verificar la existencia del mensaje*/
IF EXISTS (SELECT * FROM sys.messages WHERE message_id = 50001)
BEGIN
    EXEC sp_dropmessage 50001;
END

/*Crear un nuevo mensaje*/
EXEC sp_addmessage 
    @msgnum = 50001, 
    @severity = 16, 
    @msgtext = 'Ocurrió un error inesperado, porfavor compruebe los datos que desea ingresar';


/*Verificar la existencia del mensaje*/
IF EXISTS (SELECT * FROM sys.messages WHERE message_id = 50002)
BEGIN
    EXEC sp_dropmessage 50002;
END

/*Crear un nuevo mensaje*/
EXEC sp_addmessage 
    @msgnum = 50002, 
    @severity = 16, 
    @msgtext = 'Porfavor, comprueba los datos que estás ingresando';

/*Verificar la existencia del mensaje*/
IF EXISTS (SELECT * FROM sys.messages WHERE message_id = 50003)
BEGIN
    EXEC sp_dropmessage 50003;
END

/*Crear un nuevo mensaje*/
EXEC sp_addmessage 
    @msgnum = 50003, 
    @severity = 16, 
    @msgtext = 'El RUC que ingresaste no es válido';

/*Verificar la existencia del mensaje*/
IF EXISTS (SELECT * FROM sys.messages WHERE message_id = 50004)
BEGIN
    EXEC sp_dropmessage 50004;
END

/*Crear un nuevo mensaje*/
EXEC sp_addmessage 
    @msgnum = 50004, 
    @severity = 16, 
    @msgtext = 'La cédula de la persona no es válida';

/************************************************ Creación de tipos de datos personalizados ****************************************/

/*Verifiación de existencia del tipo de datos teléfono, y creación del mismo*/
IF EXISTS(SELECT name FROM sys.systypes WHERE name = 'telefono')
BEGIN
    DROP TYPE telefono;
END
GO

CREATE TYPE telefono FROM char(10) NOT NULL;
GO

/*Verifiación de existencia del tipo de datos email, y creación del mismo*/
IF EXISTS(SELECT name FROM sys.systypes WHERE name = 'email')
BEGIN
    DROP TYPE email;
END
GO

CREATE TYPE email FROM varchar(255) NOT NULL;
GO

/*********************************************** Creación de reglas asociadas a los tipos de datos ****************************************/

/*Creación de la regla para emails*/
CREATE RULE rl_email
AS
    @value LIKE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'; --VALIDAR
GO

/*Asociación de la regla con el tipo de datos email*/
sp_bindrule 'rl_email', 'email';
GO


/*Creación de la regla para teléfono*/
CREATE RULE rl_telefono
AS
    @value LIKE '[0-9]{7}|[0-9]{10}';
GO

/*Asociación de la regla con el tipo de datos teléfono*/
sp_bindrule 'rl_telefono', 'telefono';
GO

/********************************************** Creación de tablas de la base de datos ***************************************************/
CREATE TABLE Region(

	idRegion TINYINT IDENTITY(1,1),
	nombre NVARCHAR(8) NOT NULL,

	CONSTRAINT PK_Region PRIMARY KEY (idRegion),
	CONSTRAINT CH_NombreRegion CHECK (nombre IN ('Insular', 'Sierra', 'Costa', 'Amazonía'))
)
GO

CREATE TABLE Provincia(

	idProvincia TINYINT IDENTITY(1,1),
	nombre NVARCHAR(30) NOT NULL UNIQUE,
	idRegion TINYINT NOT NULL,

	CONSTRAINT PK_Provincia PRIMARY KEY (idProvincia),
	CONSTRAINT FK_ProvinciaRegion FOREIGN KEY (idRegion) REFERENCES REGION(idRegion),
	CONSTRAINT UQ_ProvinciaRegion UNIQUE (idProvincia, idRegion),
	CONSTRAINT CH_NombreProvincia CHECK (nombre IN ('Azuay', 'Bolívar', 'Cañar', 'Carchi', 'Chimborazo', 
	'Cotopaxi', 'El Oro', 'Esmeraldas', 'Galápagos', 'Guayas', 'Imbabura', 'Loja', 'Los Ríos', 
	'Manabí', 'Morona Santiago', 'Napo', 'Orellana', 'Pastaza', 'Pichincha', 'Santa Elena', 
	'Santo Domingo de los Tsáchilas', 'Sucumbíos', 'Tungurahua', 'Zamora Chinchipe'))
)
GO

CREATE TABLE Ciudad(

	idCiudad TINYINT IDENTITY(1,1),
	nombre NVARCHAR(30) NOT NULL,
	idProvincia TINYINT NOT NULL,

	CONSTRAINT PK_Ciudad PRIMARY KEY (idCiudad),
	CONSTRAINT UQ_CiudadProvincia UNIQUE (idProvincia, nombre), -- VERIFICAR QUE NO SE REPITA UNA CIUDAD DOS VECES EN LA MISMA PROVINCIA
	CONSTRAINT FK_CiudadProvincia FOREIGN KEY (idProvincia) REFERENCES Provincia(idProvincia),
	CONSTRAINT CK_NombreCiudad CHECK (nombre LIKE '%[a-zA-Z]%')
)
GO

CREATE TABLE Cargo(
	idCargo TINYINT IDENTITY(1,1),
	nombre VARCHAR(15)  NOT NULL UNIQUE,
	permisoRecibir BIT  NOT NULL,
	permisoAnalizar BIT  NOT NULL,
	permisoAprobar BIT  NOT NULL,

	CONSTRAINT PK_Cargo PRIMARY KEY(idCargo),
	CONSTRAINT CK_NombreCargo CHECK (nombre LIKE '%[a-zA-Z]%')
)
GO

CREATE TABLE Empleado(
	idEmpleado TINYINT IDENTITY(1,1),
	cedula VARBINARY(55)  NOT NULL UNIQUE, 
	nombres NVARCHAR(55)  NOT NULL ,
	apellidos NVARCHAR(55)  NOT NULL ,
	email EMAIL  NOT NULL UNIQUE,
	telefono TELEFONO NOT NULL UNIQUE,
	fechaCreacion DATE NOT NULL DEFAULT GETDATE(),
	idCargo TINYINT NOT NULL ,
	
	CONSTRAINT PK_Empleado PRIMARY KEY (idEmpleado),
	CONSTRAINT FK_CargoEmpleado FOREIGN KEY (idCargo) REFERENCES Cargo(idCargo),
	CONSTRAINT CK_NombresEmpleado CHECK (nombres LIKE '[A-Za-z]+ [A-Za-z]+'),
	CONSTRAINT CK_ApellidosEmpleado CHECK (apellidos LIKE '[A-Za-z]+ [A-Za-z]+')
)
GO

CREATE TABLE Credencial (
	idCredencial TINYINT IDENTITY(1,1),
	usuario VARCHAR(10) NOT NULL UNIQUE,
	contrasena VARBINARY(max) NOT NULL,
	fechaCreacion  DATE NOT NULL DEFAULT GETDATE(),
	fechaContrasena DATE NOT NULL DEFAULT GETDATE(),
	idEmpleado TINYINT NOT NULL UNIQUE,

	CONSTRAINT PK_Credencial PRIMARY KEY (idCredencial),
	CONSTRAINT FK_EmpleadoCredencial FOREIGN KEY (idEmpleado) REFERENCES Empleado(idEmpleado)
)
GO

CREATE TABLE TipoCliente(

	idTipoCliente TINYINT IDENTITY(1,1),
	categoria CHAR(1) NOT NULL UNIQUE,
	porcentajeDescuento TINYINT NOT NULL UNIQUE,

	CONSTRAINT PK_TipoCliente PRIMARY KEY (idTipoCliente),
	CONSTRAINT CH_categoriaTipoCliente CHECK (LEN(categoria) = 1 AND categoria LIKE '[A-Za-z]'),
	CONSTRAINT CH_porcentajeDescuento CHECK (porcentajeDescuento >= 0 AND porcentajeDescuento <= 100)
)
GO

CREATE TABLE Cliente(
	
	idCliente SMALLINT IDENTITY(1,1),
	ruc VARBINARY(55) NOT NULL UNIQUE,
	nombre NVARCHAR(55)  NOT NULL ,
	direccion VARBINARY(max) NOT NULL,
	telefono TELEFONO NOT NULL UNIQUE,
	observacion NVARCHAR(200) ,
	idTipoCliente TINYINT NOT NULL,
	idCiudad TINYINT NOT NULL,

	CONSTRAINT PK_Cliente PRIMARY KEY (idCliente),
	CONSTRAINT FK_TipoCliente FOREIGN KEY (idTipoCliente) REFERENCES TipoCliente(idTipoCliente),
	CONSTRAINT FK_Ciudad FOREIGN KEY (idCiudad) REFERENCES Ciudad(idCiudad),
	CONSTRAINT CK_NombreCliente CHECK (nombre LIKE '%[a-zA-Z]%')
)
GO


CREATE TABLE ContactoCliente(
	
	idContactoCliente INT IDENTITY(1,1),
	cedula VARBINARY(55) NOT NULL UNIQUE,
	nombres NVARCHAR(55) NOT NULL,
	apellidos NVARCHAR(55) NOT NULL,
	telefono TELEFONO NOT NULL UNIQUE,
	email EMAIL NOT NULL UNIQUE,
	idCliente SMALLINT NOT NULL,

	CONSTRAINT PK_ContactoCliente PRIMARY KEY (idContactoCliente),
	CONSTRAINT FK_Cliente_ContactoCliente FOREIGN KEY (idCliente) REFERENCES Cliente(idCliente),
	CONSTRAINT CK_NombresContactoCliente CHECK (nombres LIKE '[A-Za-z]+ [A-Za-z]+'),
	CONSTRAINT CK_ApellidosContactoCliente CHECK (apellidos LIKE '[A-Za-z]+ [A-Za-z]+')
)
GO

CREATE TABLE Proforma(
	
	idProforma INT IDENTITY(1,1),
	fechaInicio DATE NOT NULL DEFAULT GETDATE(),
	fechaEntrega DATE,
	idCliente SMALLINT NOT NULL,
	idEmpleado TINYINT NOT NULL,

	CONSTRAINT PK_Proforma PRIMARY KEY (idProforma),
	CONSTRAINT FK_ProformaCliente FOREIGN KEY (idCliente) REFERENCES Cliente(idCliente),
	CONSTRAINT FK_ProformaEmpleado FOREIGN KEY (idEmpleado) REFERENCES Empleado(idEmpleado)
)
GO

CREATE TABLE Contenedor(

    idContenedor TINYINT IDENTITY(1,1), 
	tipo NVARCHAR(25) NOT NULL, 
	material NVARCHAR(25) NOT NULL, 
	volumen DECIMAL(10,4) NOT NULL, 
	unidadVolumen NVARCHAR(5) NOT NULL,

    CONSTRAINT PK_Contenedor PRIMARY KEY (idContenedor)
)
GO

CREATE TABLE Ensayo(

	idEnsayo TINYINT IDENTITY(1,1), 
	nombre NVARCHAR(40) NOT NULL UNIQUE, 
	siglas CHAR(5) NOT NULL UNIQUE, 
	tipo NVARCHAR(40) NOT NULL, 

    CONSTRAINT PK_Ensayo PRIMARY KEY (idEnsayo)
)
GO

CREATE TABLE Muestra(

	idMuestra INT IDENTITY(1,1), 
	contenido VARCHAR(20) NOT NULL,  
	condicion VARCHAR(20) NOT NULL,
	fecha DATE NOT NULL, 
	peso DECIMAL(10,4) NOT NULL, 
	unidadPeso NVARCHAR(5) NOT NULL,
	volumen DECIMAL(10,4) NOT NULL,
	unidadVolumen NVARCHAR(5) NOT NULL,

	idEmpleado TINYINT NOT NULL,
	idContenedor TINYINT NOT NULL, 

	CONSTRAINT PK_Muestra PRIMARY KEY (idMuestra),
	CONSTRAINT FK_EmpleadoMuestra FOREIGN KEY (idEmpleado) REFERENCES Empleado(idEmpleado),
	CONSTRAINT FK_ContenedorMuestra FOREIGN KEY (idContenedor) REFERENCES Contenedor(idContenedor)
)
GO

CREATE TABLE Insumo(

	idInsumo SMALLINT IDENTITY(1,1), 
	nombre NVARCHAR(40) NOT NULL UNIQUE, 
	tipo NVARCHAR(30) NOT NULL, 

    CONSTRAINT PK_Insumo PRIMARY KEY (idInsumo)
)
GO

CREATE TABLE Metrica(

	idMetrica SMALLINT IDENTITY(1,1), 
	nombre NVARCHAR(40) NOT NULL UNIQUE,

    CONSTRAINT PK_Metrica PRIMARY KEY (idMetrica)
)
GO

CREATE TABLE Metodo(

	idMetodo TINYINT IDENTITY(1,1), 
	nombre NVARCHAR(40) NOT NULL UNIQUE,

    CONSTRAINT PK_Metodo PRIMARY KEY (idMetodo)

)
GO

CREATE TABLE MetodoInsumo(

	idMetodo TINYINT NOT NULL, 
	idInsumo SMALLINT NOT NULL,

	cantidad DECIMAL(10,4) NOT NULL,
	unidad NVARCHAR(5) NOT NULL,

	CONSTRAINT PK_MetodoInsumo PRIMARY KEY (idMetodo, idInsumo),
	CONSTRAINT FK_MetodoInsumoMetodo FOREIGN KEY (idMetodo) REFERENCES Metodo(idMetodo),
	CONSTRAINT FK_MetodoInsumoInsumo FOREIGN KEY (idInsumo) REFERENCES Insumo(idInsumo)
)
GO

CREATE TABLE MetodoMetrica(

	idMetodo TINYINT NOT NULL, 
	idMetrica SMALLINT NOT NULL,

	minimoAceptable DECIMAL(10,4) NOT NULL, 
	maximoAceptable DECIMAL(10,4) NOT NULL, 
	valorNormal DECIMAL(10,4) NOT NULL, 
	unidad NVARCHAR(5) NOT NULL, 

	CONSTRAINT PK_MetodoMetrica PRIMARY KEY (idMetodo, idMetrica),
	CONSTRAINT FK_MetodoMetricaMetodo FOREIGN KEY (idMetodo) REFERENCES Metodo(idMetodo),
	CONSTRAINT FK_MetodoMetricaMetrica FOREIGN KEY (idMetrica) REFERENCES Metrica(idMetrica),
	CONSTRAINT CH_MinimoMaximo CHECK (minimoAceptable <= valorNormal AND valorNormal <= maximoAceptable)
)
GO

CREATE TABLE Analisis(

	idAnalisis TINYINT IDENTITY(1,1), 
	nombre NVARCHAR(40) NOT NULL UNIQUE,

    CONSTRAINT PK_Analisis PRIMARY KEY (idAnalisis)

)
GO

CREATE TABLE Servicio(

	idServicio SMALLINT IDENTITY(1,1), 

	precioReferencial DECIMAL (7,2) NOT NULL,
	idEnsayo TINYINT NOT NULL,  
	idAnalisis TINYINT NOT NULL, 
	idMetodo TINYINT NOT NULL,

	CONSTRAINT PK_Servicio PRIMARY KEY (idServicio),
	CONSTRAINT FK_ServicioEnsayo FOREIGN KEY (idEnsayo) REFERENCES Ensayo(idEnsayo),
	CONSTRAINT FK_ServicioAnalisis FOREIGN KEY (idAnalisis) REFERENCES Analisis(idAnalisis),
	CONSTRAINT FK_ServicioMetodo FOREIGN KEY (idMetodo) REFERENCES Metodo(idMetodo),
	CONSTRAINT UQ_Servicio UNIQUE (idEnsayo, idAnalisis, idMetodo)
)
GO

CREATE TABLE Resultado(

	idResultado INT IDENTITY(1,1), 
	
	resultado DECIMAL(10,4) NOT NULL,
	fechaEjecucion DATE NOT NULL, 
	idEmpleado TINYINT NOT NULL,

	CONSTRAINT PK_Resultado PRIMARY KEY (idResultado),
	CONSTRAINT FK_EmpleadoResultado FOREIGN KEY (idEmpleado) REFERENCES Empleado(idEmpleado)
)
GO

CREATE TABLE Contrato(

	idContrato INT IDENTITY(1,1),

	observacion NVARCHAR(200),
	idProforma INT NOT NULL, 
	idServicio SMALLINT NOT NULL, 
	idMuestra INT NOT NULL, 
	idResultado INT, 

	CONSTRAINT PK_Contrato PRIMARY KEY (idResultado),
	CONSTRAINT FK_ContratoProforma FOREIGN KEY (idProforma) REFERENCES Proforma(idProforma),
	CONSTRAINT FK_ContratoServicio FOREIGN KEY (idServicio) REFERENCES Servicio(idServicio),
	CONSTRAINT FK_ContratoMuestra FOREIGN KEY (idMuestra) REFERENCES Muestra(idMuestra),
	CONSTRAINT FK_ContratoResultado FOREIGN KEY (idResultado) REFERENCES Resultado(idResultado),

	CONSTRAINT UQ_Contrato UNIQUE(idProforma, idServicio, idResultado)
)
GO

/************************************************ Creación de objetos programables *************************************************/

--1. Listado de ensayos realizados en un periodo 
--2. Resultados de un contrato
--3. Ensayos históricos de un cliente

----------------------------------------------------------------------------------------------FUNCIONES
/*Validación de existencia de la función fn_validarCI*/
IF OBJECT_ID('fn_validarCI', 'FN') IS NOT NULL
BEGIN
    DROP FUNCTION [fn_validarCI]
END
GO
/*Creación de una función de validación de cedulas ecuatorianas*/
CREATE FUNCTION fn_validarCI (@cedula VARCHAR(10))
RETURNS BIT
AS
BEGIN
    DECLARE @resultado BIT = 0;
    DECLARE @provincia INT, @genero INT, @verificador INT, @suma INT = 0, @ultimo INT;
    IF (LEN(@cedula) <> 10) RETURN 0;
	IF (ISNUMERIC(@cedula) = 0) RETURN 0;
    SET @provincia = CAST(SUBSTRING(@cedula, 1, 2) AS INT);
    SET @genero = CAST(SUBSTRING(@cedula, 3, 1) AS INT);
    SET @verificador = CAST(SUBSTRING(@cedula, 10, 1) AS INT);
    IF (@provincia < 1 OR @provincia > 24) RETURN 0;
    IF (@genero < 0 OR @genero > 6) RETURN 0;
    IF (@verificador < 0 OR @verificador > 9) RETURN 0;
    SET @suma = CAST(SUBSTRING(@cedula, 1, 1) AS INT) * 2 +
                CAST(SUBSTRING(@cedula, 2, 1) AS INT) * 1 +
                CAST(SUBSTRING(@cedula, 3, 1) AS INT) * 2 +
                CAST(SUBSTRING(@cedula, 4, 1) AS INT) * 1 +
                CAST(SUBSTRING(@cedula, 5, 1) AS INT) * 2 +
                CAST(SUBSTRING(@cedula, 6, 1) AS INT) * 1 +
                CAST(SUBSTRING(@cedula, 7, 1) AS INT) * 2 +
                CAST(SUBSTRING(@cedula, 8, 1) AS INT) * 1 +
                CAST(SUBSTRING(@cedula, 9, 1) AS INT) * 2;
    SET @ultimo = 10 - RIGHT(CAST(@suma AS VARCHAR(2)), 1);
    IF (@ultimo = 10) SET @ultimo = 0;
    IF (@ultimo = @verificador) SET @resultado = 1;
    RETURN @resultado;
END;
GO


/*Validación de existencia de la función fn_validarRUCPersonas*/
IF OBJECT_ID('fn_validarRUCPersonas', 'FN') IS NOT NULL
BEGIN
    DROP FUNCTION [fn_validarRUCPersonas]
END
GO
/*Creación de una función de validación de ruc de personas naturales ecuatorianas*/
CREATE FUNCTION fn_validarRUCPersonas (@ruc VARCHAR(13))
RETURNS BIT
AS
BEGIN
    DECLARE @resultado BIT = 0;
    DECLARE @provincia INT, @genero INT, @verificador INT, @suma INT = 0, @ultimo INT, @ultimostres INT;
    IF (LEN(@ruc) <> 13) RETURN 0;
	IF (ISNUMERIC(@ruc) = 0) RETURN 0;
    SET @provincia = CAST(SUBSTRING(@ruc, 1, 2) AS INT);
    SET @genero = CAST(SUBSTRING(@ruc, 3, 1) AS INT);
    SET @verificador = CAST(SUBSTRING(@ruc, 10, 1) AS INT);
	SET @ultimostres = CAST(SUBSTRING(@ruc, 11, 3) AS INT);
    IF (@provincia < 1 OR @provincia > 24) RETURN 0;
    IF (@genero < 0 OR @genero > 6) RETURN 0;
	IF (@ultimostres <> 001) RETURN 0;
    IF (@verificador < 0 OR @verificador > 9) RETURN 0;
    SET @suma = CAST(SUBSTRING(@ruc, 1, 1) AS INT) * 2 +
                CAST(SUBSTRING(@ruc, 2, 1) AS INT) * 1 +
                CAST(SUBSTRING(@ruc, 3, 1) AS INT) * 2 +
                CAST(SUBSTRING(@ruc, 4, 1) AS INT) * 1 +
                CAST(SUBSTRING(@ruc, 5, 1) AS INT) * 2 +
                CAST(SUBSTRING(@ruc, 6, 1) AS INT) * 1 +
                CAST(SUBSTRING(@ruc, 7, 1) AS INT) * 2 +
                CAST(SUBSTRING(@ruc, 8, 1) AS INT) * 1 +
                CAST(SUBSTRING(@ruc, 9, 1) AS INT) * 2;
    SET @ultimo = 10 - RIGHT(CAST(@suma AS VARCHAR(2)), 1);
    IF (@ultimo = 10) SET @ultimo = 0;
    IF (@ultimo = @verificador) SET @resultado = 1;
    RETURN @resultado;
END;
GO


/*Validación de existencia de la función fn_validarRUCPrivadas*/
IF OBJECT_ID('fn_validarRUCPrivadas', 'FN') IS NOT NULL
BEGIN
    DROP FUNCTION [fn_validarRUCPrivadas]
END
GO
/*Creación de una función de validación de ruc de sociedades privadas ecuatorianas*/
CREATE FUNCTION fn_validarRUCPrivadas (@ruc VARCHAR(13))
RETURNS BIT
AS
BEGIN
    DECLARE @resultado BIT = 0;
    DECLARE @provincia INT, @nueve INT, @ultimostres INT;
    IF (LEN(@ruc) <> 13) RETURN 0;
	IF (ISNUMERIC(@ruc) = 0) RETURN 0;
    SET @provincia = CAST(SUBSTRING(@ruc, 1, 2) AS INT);
    SET @nueve = CAST(SUBSTRING(@ruc, 3, 1) AS INT);
	SET @ultimostres = CAST(SUBSTRING(@ruc, 11, 3) AS INT);
    IF (@provincia < 1 OR @provincia > 24) RETURN 0;
	IF (@nueve <> 9) RETURN 0;
	IF (@ultimostres <> 001) RETURN 0;
    SET @resultado = 1;
    RETURN @resultado;
END;
GO


/*Validación de existencia de la función fn_validarRUCPublicas*/
IF OBJECT_ID('fn_validarRUCPublicas', 'FN') IS NOT NULL
BEGIN
    DROP FUNCTION [fn_validarRUCPublicas]
END
GO
/*Creación de una función de validación de ruc de sociedades públicas ecuatorianas*/
CREATE FUNCTION fn_validarRUCPublicas (@ruc VARCHAR(13))
RETURNS BIT
AS
BEGIN
    DECLARE @resultado BIT = 0;
    DECLARE @provincia INT, @nueveoseis INT, @ultimostres INT;
    IF (LEN(@ruc) <> 13) RETURN 0;
	IF (ISNUMERIC(@ruc) = 0) RETURN 0;
    SET @provincia = CAST(SUBSTRING(@ruc, 1, 2) AS INT);
    SET @nueveoseis = CAST(SUBSTRING(@ruc, 3, 1) AS INT);
	SET @ultimostres = CAST(SUBSTRING(@ruc, 11, 3) AS INT);
    IF (@provincia < 1 OR @provincia > 24) RETURN 0;
	IF (@nueveoseis <> 9 AND @nueveoseis <> 6) RETURN 0;
	IF (@ultimostres <> 001) RETURN 0;
    SET @resultado = 1;
    RETURN @resultado;
END;
GO


/*Validación de existencia de la función fn_EncriptarCedula*/
IF OBJECT_ID('fn_EncriptarCedula', 'FN') IS NOT NULL
BEGIN
    DROP FUNCTION [fn_EncriptarCedula]
END
GO
/*Creación de una función de encriptación de cedulas*/
CREATE FUNCTION fn_EncriptarCedula (@cedula VARCHAR(10)) 
RETURNS VARBINARY(max) 
AS 
BEGIN 
	DECLARE @cedulaEN VARBINARY(max) 
	SET @cedulaEN = EncryptByKey(Key_GUID('SymKey_test'), @cedula)
	RETURN @cedulaEN;
END;
GO


/*Validación de existencia de la función fn_DesencriptarCedula*/
IF OBJECT_ID('fn_DesencriptarCedula', 'FN') IS NOT NULL
BEGIN
    DROP FUNCTION [fn_DesencriptarCedula]
END
GO
/*Creación de una función de desencriptación de cedulas*/
CREATE FUNCTION fn_DesencriptarCedula (@cedulaEN VARBINARY(max) ) 
RETURNS VARCHAR(10) 
AS 
BEGIN 
	DECLARE @cedula varchar(10)
	SET @cedula = CONVERT(varchar, DecryptByKey(@cedulaEN))
	RETURN @cedula;
END;
GO

/*Validación de existencia de la función fn_EncriptarRUC*/
IF OBJECT_ID('fn_EncriptarRUC', 'FN') IS NOT NULL
BEGIN
    DROP FUNCTION [fn_EncriptarRUC]
END
GO
/*Creación de una función de encriptación de rucs*/
CREATE FUNCTION fn_EncriptarRUC (@ruc VARCHAR(13)) 
RETURNS VARBINARY(max) 
AS 
BEGIN 
	DECLARE @rucEN VARBINARY(max) 
	SET @rucEN = EncryptByKey(Key_GUID('SymKey_test'), @ruc)
	RETURN @rucEN;
END;
GO


/*Validación de existencia de la función fn_DesencriptarRUC*/
IF OBJECT_ID('fn_DesencriptarRUC', 'FN') IS NOT NULL
BEGIN
    DROP FUNCTION [fn_DesencriptarRUC]
END
GO
/*Creación de una función de desencriptación de rucs*/
CREATE FUNCTION fn_DesencriptarRUC (@rucEN VARBINARY(max) ) 
RETURNS VARCHAR(13) 
AS 
BEGIN 
	DECLARE @ruc varchar(13)
	SET @ruc = CONVERT(varchar, DecryptByKey(@rucEN))
	RETURN @ruc;
END;
GO


/*Validación de existencia de la función fn_EncriptarDireccion*/
IF OBJECT_ID('fn_EncriptarDireccion', 'FN') IS NOT NULL
BEGIN
    DROP FUNCTION [fn_EncriptarDireccion]
END
GO
/*Creación de una función de encriptación de direcciones*/
CREATE FUNCTION fn_EncriptarDireccion (@direccion NVARCHAR(250)) 
RETURNS VARBINARY(max) 
AS 
BEGIN 
	DECLARE @direccionEN VARBINARY(max) 
	SET @direccionEN = EncryptByKey(Key_GUID('SymKey_test'), @direccion)
	RETURN @direccionEN;
END;
GO


/*Validación de existencia de la función fn_DesencriptarRUC*/
IF OBJECT_ID('fn_DesencriptarDireccion', 'FN') IS NOT NULL
BEGIN
    DROP FUNCTION [fn_DesencriptarDireccion]
END
GO
/*Creación de una función de desencriptación de cedulas*/
CREATE FUNCTION fn_DesencriptarDireccion (@direccionEN VARBINARY(max) ) 
RETURNS NVARCHAR(250) 
AS 
BEGIN 
	DECLARE @direccion NVARCHAR(250) 
	SET @direccion = CONVERT(varchar, DecryptByKey(@direccionEN))
	RETURN @direccion;
END;
GO
----------------------------------------------------------------------------------------------STORED PROCEDURES

/*Validación de existencia del stored procedure sp_InsertarEncriptados*/
IF OBJECT_ID('sp_InsertarEncriptados', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE [sp_InsertarEncriptados]
END
GO
/*Creación de un stored procedure para encriptar las ceduals EJEMPLO*/
CREATE PROCEDURE sp_InsertarEncriptados (@cedula varchar(10))
AS
BEGIN
	OPEN SYMMETRIC KEY SymKey_test
	DECRYPTION BY CERTIFICATE Certificate_test;
	DECLARE @dato VARBINARY(max) 
	SET @dato = dbo.fn_EncriptarCedula(@cedula)
	INSERT INTO Encriptados(dato) values(@dato)
	CLOSE SYMMETRIC KEY SymKey_test;
END;
GO


/*Verificar la existencia del sp*/
IF OBJECT_ID('sp_IngresarAnalisis', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_IngresarAnalisis
END
GO
/*Creación del procedure para ingresar Análisis*/
CREATE PROCEDURE sp_IngresarAnalisis(@nombre NVARCHAR(40))
AS
BEGIN
	BEGIN TRY
	INSERT INTO Analisis(nombre) VALUES(@nombre)
	END TRY
	BEGIN CATCH
		IF ERROR_NUMBER() = 547
			RAISERROR(50002,16,10)
		ELSE
			RAISERROR(50001,16,10)
	END CATCH;
END


/*Verificar la existencia del sp*/
IF OBJECT_ID('sp_IngresarCargo', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_IngresarCargo
END
GO
/*Creación del procedure para ingresar Cargos*/
CREATE PROCEDURE sp_IngresarCargo(@nombre NVARCHAR(40), @permisoRecibir BIT, @permisoAnalizar BIT, @permisoAprobar BIT)
AS 
BEGIN
	BEGIN TRY
	INSERT INTO Cargo(nombre,permisoRecibir,permisoAnalizar,permisoAprobar) VALUES(@nombre,@permisoRecibir,@permisoAnalizar,@permisoAprobar)
	END TRY
	BEGIN CATCH
		IF ERROR_NUMBER() = 547
			RAISERROR(50002,16,10)
		ELSE
			RAISERROR(50001,16,10)
	END CATCH;
END


/*Verificar la existencia del sp*/
IF OBJECT_ID('sp_IngresarCiudad', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_IngresarCiudad
END
GO
/*Creación del procedure para ingresar Ciudades*/
CREATE PROCEDURE sp_IngresarCiudad(@nombre NVARCHAR(30), @provincia NVARCHAR(30))
AS 
BEGIN
	DECLARE @idProvincia TINYINT;
	BEGIN TRY
		SET @idProvincia = (SELECT idProvincia FROM Provincia WHERE nombre = @provincia)
		INSERT INTO Ciudad(nombre,idProvincia) VALUES(@nombre,@idProvincia)
	END TRY
	BEGIN CATCH
		IF ERROR_NUMBER() = 547
			RAISERROR(50002,16,10)
		ELSE
			RAISERROR(50001,16,10)
	END CATCH;
END


/*Verificar la existencia del sp*/
IF OBJECT_ID('sp_IngresarRegion', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_IngresarRegion
END
GO
/*Creación del procedure para ingresar Regiones*/
CREATE PROCEDURE sp_IngresarRegion(@nombre NVARCHAR(8))
AS 
BEGIN
	BEGIN TRY
		INSERT INTO Region(nombre) VALUES(@nombre)
	END TRY
	BEGIN CATCH
		IF ERROR_NUMBER() = 547
			RAISERROR(50002,16,10)
		ELSE
			RAISERROR(50001,16,10)
	END CATCH;
END


/*Verificar la existencia del sp*/
IF OBJECT_ID('sp_IngresarProvincia', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_IngresarProvincia
END
GO
/*Creación del procedure para ingresar Provincias*/
CREATE PROCEDURE sp_IngresarProvincia(@nombre NVARCHAR(30), @region NVARCHAR(8))
AS 
BEGIN
	DECLARE @idRegion TINYINT;
	BEGIN TRY
		SET @idRegion = (SELECT idRegion FROM Region WHERE nombre = @region)
		INSERT INTO Provincia(nombre,idRegion) VALUES(@nombre,@idRegion)
	END TRY
	BEGIN CATCH
		IF ERROR_NUMBER() = 547
			RAISERROR(50002,16,10)
		ELSE
			RAISERROR(50001,16,10)
	END CATCH;
END


/*Verificar la existencia del sp*/
IF OBJECT_ID('sp_IngresarCliente', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_IngresarCliente
END
GO
/*Creación del procedure para ingresar Clientes*/
CREATE PROCEDURE sp_IngresarCliente(@ruc NVARCHAR(13), @nombre NVARCHAR(55), @direccion NVARCHAR(250), @telefono CHAR(10), 
									@observacion NVARCHAR(200), @tipoCliente CHAR(1), @ciudad NVARCHAR(30))
AS 
BEGIN
	DECLARE @rucEN VARBINARY(max)
	DECLARE @direccionEN VARBINARY(max)
	DECLARE @idTipoCliente TINYINT
	DECLARE @idCiudad TINYINT
	OPEN SYMMETRIC KEY SymKey_test
	DECRYPTION BY CERTIFICATE Certificate_test
	BEGIN TRY
		
		IF dbo.fn_validarRUCPersonas(@ruc) = 1 OR dbo.fn_validarPrivadas(@ruc) = 1 OR dbo.fn_validarRUCPublicas(@ruc) = 1
		BEGIN
			SET @rucEN = (SELECT dbo.fn_EncriptarRUC(@ruc))
			SET @direccionEN = (SELECT dbo.fn_EncriptarDireccion(@direccion))
			SET @idTipoCliente = (SELECT idTipoCliente FROM TipoCliente WHERE categoria = @tipoCliente)
			SET @idCiudad = (SELECT idCiudad FROM Ciudad WHERE nombre = @ciudad)

			INSERT INTO Cliente(ruc,nombre,direccion,telefono,observacion,idTipoCliente,idCiudad) 
			VALUES(@rucEN,@nombre,@direccionEN,@telefono,@observacion,@idTipoCliente,@idCiudad)
		END
		ELSE
		BEGIN
			RAISERROR(50003,16,10)
		END
	END TRY
	BEGIN CATCH
		IF ERROR_NUMBER() = 547
			RAISERROR(50002,16,10)
		ELSE
			RAISERROR(50001,16,10)
	END CATCH;
	CLOSE SYMMETRIC KEY SymKey_test;
END


/*Verificar la existencia del sp*/
IF OBJECT_ID('sp_IngresarContactoCliente', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_IngresarContactoCliente
END
GO
/*Creación del procedure para ingresar Contactos de Clientes*/
CREATE PROCEDURE sp_IngresarContactoCliente(@cedula VARCHAR(10), @nombre NVARCHAR(55), @apellidos NVARCHAR(55), @telefono CHAR(10), 
									@email EMAIL, @nombreCliente NVARCHAR(55))
AS 
BEGIN
	DECLARE @cedulaEN VARBINARY(max)
	DECLARE @idCliente SMALLINT
	OPEN SYMMETRIC KEY SymKey_test
	DECRYPTION BY CERTIFICATE Certificate_test
	BEGIN TRY
		IF dbo.fn_validarCI(@cedula) = 1
		BEGIN
			SET @cedulaEN = (SELECT dbo.fn_EncriptarCedula(@cedula))
			SET @idCliente = (SELECT idCliente FROM Cliente WHERE nombre = @nombreCliente)

			INSERT INTO ContactoCliente(cedula,nombres,apellidos,telefono,email,idCliente) 
			VALUES(@cedulaEN,@nombre,@apellidos,@telefono,@email,@idCliente)
		END
		ELSE
		BEGIN
			RAISERROR(50004,16,10)
		END
	END TRY
	BEGIN CATCH
		IF ERROR_NUMBER() = 547
			RAISERROR(50002,16,10)
		ELSE
			RAISERROR(50001,16,10)
	END CATCH;
	CLOSE SYMMETRIC KEY SymKey_test;
END


/*Verificar la existencia del sp*/
IF OBJECT_ID('sp_IngresarEmpleado', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_IngresarEmpleado
END
GO
/*Creación del procedure para ingresar Empleados*/
CREATE PROCEDURE sp_IngresarEmpleado(@cedula VARCHAR(10), @nombre NVARCHAR(55), @apellidos NVARCHAR(55), @email EMAIL, @telefono CHAR(10), @nombreCargo VARCHAR(15))
AS 
BEGIN
	DECLARE @cedulaEN VARBINARY(max)
	DECLARE @idCargo SMALLINT
	DECLARE @fechaCreacion DATETIME

	OPEN SYMMETRIC KEY SymKey_test
	DECRYPTION BY CERTIFICATE Certificate_test
	BEGIN TRY
		IF dbo.fn_validarCI(@cedula) = 1
		BEGIN
			SET @cedulaEN = (SELECT dbo.fn_EncriptarCedula(@cedula))
			SET @idCargo = (SELECT idCargo FROM Cargo WHERE nombre = @nombreCargo)
			SET @fechaCreacion = GETDATE()

			INSERT INTO Empleado(cedula,nombres,apellidos,email,telefono,fechaCreacion,idCargo) 
			VALUES(@cedulaEN,@nombre,@apellidos,@email,@telefono,@fechaCreacion,@idCargo)
		END
		ELSE
		BEGIN
			RAISERROR(50004,16,10)
		END
	END TRY
	BEGIN CATCH
		IF ERROR_NUMBER() = 547
			RAISERROR(50002,16,10)
		ELSE
			RAISERROR(50001,16,10)
	END CATCH;
	CLOSE SYMMETRIC KEY SymKey_test;
END




----------------------------------------------------------------------------------------------VISTAS

/*Código para abrir la llave, presentar información desencriptada y luego cerrar la llave EJEMPLO*/
/*OPEN SYMMETRIC KEY SymKey_test
	DECRYPTION BY CERTIFICATE Certificate_test;
SELECT dbo.fn_DesencriptarCedula(dato) FROM Encriptados
CLOSE SYMMETRIC KEY SymKey_test;*/

/************************************************* Primera consideración de ciberseguridad: limitar permisos (Pt 2) **************************************************/

/*Deshabilitar el usuario sa*/
ALTER LOGIN sa DISABLE;
GO
/*Inhabilitar el guest*/
REVOKE CONNECT FROM Guest
GO

/*Atribuirles permisos a los usuarios*/

/*Denegar permisos a los usuarios*/

/************************************************* Quemar datos **************************************************/


/************************************************* Objetos programables para presentar informes **************************************************/


/************************************************* Notificaciones por correo **************************************************/

--1. Emisión de informe de resultados de ensayo 
--2. Notificación a empleado de su registro


/************************************************* Tercera consideración de ciberseguridad: copias de seguridad programadas *************************************************/
USE msdb;
GO

-- Check if the job exists and drop it if it does
IF EXISTS (SELECT job_id FROM dbo.sysjobs WHERE name = N'BackupJob')
BEGIN
    EXEC dbo.sp_delete_job @job_name = N'BackupJob';
END

-- Create a new job
EXEC dbo.sp_add_job
    @job_name = N'BackupJob',
    @enabled = 1,
    @description = N'Automatic backup job';

-- Check if the step exists and drop it if it does
IF EXISTS (SELECT step_id FROM dbo.sysjobsteps WHERE step_name = N'BackupStep' AND job_id = (SELECT job_id FROM dbo.sysjobs WHERE name = N'BackupJob'))
BEGIN
    EXEC dbo.sp_delete_jobstep @job_name = N'BackupJob', @step_name = N'BackupStep';
END

-- Add a new job step to perform the backup
EXEC dbo.sp_add_jobstep
    @job_name = N'BackupJob',
    @step_name = N'BackupStep',
    @subsystem = N'TSQL',
    @command = N'BACKUP DATABASE Laboratorio TO DISK = ''C:\Backup\Laboratorio.bak''',
    @retry_attempts = 5,
    @retry_interval = 5;

-- Check if the schedule exists and drop it if it does
IF EXISTS (SELECT schedule_id FROM dbo.sysschedules WHERE name = N'BackupSchedule')
BEGIN
    EXEC dbo.sp_delete_schedule @schedule_name = N'BackupSchedule';
END

-- Schedule the job to run every two days
EXEC dbo.sp_add_schedule
    @schedule_name = N'BackupSchedule',
    @enabled = 1,
    @freq_type = 4, -- Daily
    @freq_interval = 2, -- Every 2 days
    @active_start_time = 100000, -- 10:00 AM
    @schedule_uid = NULL;

-- Associate the job with the schedule
EXEC dbo.sp_attach_schedule
    @job_name = N'BackupJob',
    @schedule_name = N'BackupSchedule';

-- Associate the job with a job server
EXEC dbo.sp_add_jobserver
    @job_name = N'BackupJob',
    @server_name = N'(local)'; -- Replace with the name of your SQL Server instance if necessary

-- Start the job
EXEC dbo.sp_start_job N'BackupJob';

