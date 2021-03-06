
-- Drop the foreign keys
IF EXISTS
(
    SELECT *
FROM sys.foreign_keys
WHERE object_id = OBJECT_ID(N'FK__Table2_Table1')
    AND parent_object_id = OBJECT_ID(N'dbo.Table2')
)
    ALTER TABLE [dbo].[Table2] DROP CONSTRAINT [FK__Table2_Table1];

IF EXISTS
(
    SELECT *
FROM sys.foreign_keys
WHERE object_id = OBJECT_ID(N'FK__Table3_Table2')
    AND parent_object_id = OBJECT_ID(N'dbo.Table3')
)
    ALTER TABLE [dbo].[Table3] DROP CONSTRAINT [FK__Table3_Table2];
GO

-- Dropping procedures
DROP PROCEDURE IF EXISTS [dbo].[Proc1];
DROP PROCEDURE IF EXISTS [dbo].[Proc2];
DROP PROCEDURE IF EXISTS [dbo].[Proc3];
GO

-- Dropping views
DROP VIEW IF EXISTS [dbo].[View1];
DROP VIEW IF EXISTS [dbo].[View2];
DROP VIEW IF EXISTS [dbo].[View3];
DROP VIEW IF EXISTS [dbo].[View4];

-- Dropping functions
DROP FUNCTION IF EXISTS [dbo].[RandomNumberFunction];
DROP FUNCTION IF EXISTS [dbo].[SayHello];
DROP FUNCTION IF EXISTS [dbo].[Function1];
GO

-- Dropping tables
DROP TABLE IF EXISTS [dbo].[Table1];
DROP TABLE IF EXISTS [dbo].[Table2];
DROP TABLE IF EXISTS [dbo].[Table3];
GO

-- Dropping data types
DROP TYPE IF EXISTS [dbo].[DataType1];
DROP TYPE IF EXISTS [dbo].[DataType2];
DROP TYPE IF EXISTS [dbo].[DataType3];
GO

-- Dropping table types
DROP TYPE IF EXISTS [dbo].[TableType1];
DROP TYPE IF EXISTS [dbo].[TableType2];
GO

-- Dropping schemas
DROP SCHEMA IF EXISTS [Schema1];
DROP SCHEMA IF EXISTS [Schema2];
DROP SCHEMA IF EXISTS [Schema3];
DROP SCHEMA IF EXISTS [Schema4];
GO

-- Creating schemas
CREATE SCHEMA [Schema1];
GO
CREATE SCHEMA [Schema2];
GO
CREATE SCHEMA [Schema3];
GO
CREATE SCHEMA [Schema4];
GO

-- Create the tables
CREATE TABLE [dbo].[Table1]
(
    id INT NOT NULL,
    column1 VARCHAR(20) NOT NULL,
    column2 VARCHAR(30) NULL,
    column3 BIGINT NOT NULL,
    CONSTRAINT [PK_Table1]
        PRIMARY KEY (id)
);

CREATE NONCLUSTERED INDEX [NIX__Table1_column2]
ON [dbo].[Table1] (column2);
GO

CREATE TABLE [dbo].[Table2]
(
    id INT NOT NULL,
    column1 VARCHAR(20) NOT NULL,
    column2 VARCHAR(30) NULL,
    table1id INT NOT NULL,
    CONSTRAINT [PK_Table2]
        PRIMARY KEY (id),
    CONSTRAINT [FK__Table2_Table1]
        FOREIGN KEY (table1id)
        REFERENCES [dbo].[Table1] (id)
);

CREATE NONCLUSTERED INDEX [NIX__Table2_table1id]
ON [dbo].[Table2] (table1id);
GO

CREATE NONCLUSTERED INDEX [NIX__Table2_column2]
ON [dbo].[Table2] (column2);
GO

CREATE TABLE [dbo].[Table3]
(
    id INT NOT NULL,
    column1 VARCHAR(20) NOT NULL,
    column2 VARCHAR(30) NULL,
    table2id INT NOT NULL,
    CONSTRAINT [PK_Table3]
        PRIMARY KEY (id),
    CONSTRAINT [FK__Table3_Table2]
        FOREIGN KEY (table2id)
        REFERENCES [dbo].[Table2] (id)
);
GO

CREATE NONCLUSTERED INDEX [NIX__Table3_table2id]
ON [dbo].[Table3] (table2id);
GO

CREATE NONCLUSTERED INDEX [NIX__Table3_column2]
ON [dbo].[Table3] (column2);
GO

-- Creating data types
CREATE TYPE [dbo].[DataType1] FROM [BIGINT] NOT NULL;
CREATE TYPE [dbo].[DataType2] FROM [INT] NOT NULL;
CREATE TYPE [dbo].[DataType3] FROM [SMALLINT] NOT NULL;
GO

-- Creating table types
CREATE TYPE [dbo].[TableType1] AS TABLE
(
    [id] [VARCHAR](50) NOT NULL,
    [column1] [VARCHAR](30) NOT NULL,
    [column2] [VARCHAR](50) NULL
);

CREATE TYPE [dbo].[TableType2] AS TABLE
(
    [id] [VARCHAR](50) NOT NULL,
    [column1] [VARCHAR](30) NOT NULL,
    [column2] [VARCHAR](50) NULL
);
GO

-- Create the user defined functions
CREATE FUNCTION [dbo].[Function1]
()
RETURNS INT
AS
BEGIN
    RETURN 1;
END;
GO

CREATE FUNCTION [dbo].[RandomNumberFunction]
(
    @MaxValue INT = NULL
)
RETURNS INT
AS
BEGIN
    DECLARE @result INT;
    DECLARE @random DECIMAL(18, 8);
    SELECT @random = RandomResult
    FROM dbo.RandomNumberView;

    SELECT @result = ROUND(@random * @MaxValue, 0);

    RETURN @result;
END;
GO

CREATE FUNCTION [dbo].[SayHello]
(
    @name VARCHAR(100)
)
RETURNS VARCHAR(120)
AS
BEGIN
    DECLARE @text VARCHAR(120);

    SET @text = COALESCE('Hello', ' ', @name);

    -- Return the result of the function
    RETURN @text;

END;
GO

-- Create procedures
CREATE PROCEDURE [dbo].[Proc1]
AS
SELECT 'Proc1';
GO

CREATE PROCEDURE [dbo].[Proc2]
    @id AS INT
AS
BEGIN
    SELECT *
    FROM [dbo].[Table1]
    WHERE id = @id;
END;
GO

CREATE PROCEDURE [dbo].[Proc3]
AS
SELECT 'Proc3';
GO

-- Create views
CREATE VIEW [dbo].[View1]
AS
    SELECT *
    FROM dbo.Table1;
GO
CREATE VIEW [dbo].[View2]
AS
    SELECT *
    FROM dbo.Table2;
GO
CREATE VIEW [dbo].[View3]
AS
    SELECT *
    FROM dbo.Table3;
GO
CREATE VIEW [dbo].[View4]
AS
    SELECT T3.id,
        T3.column1 AS [C11],
        T3.column2 AS [C12],
        T3.table2id AS [T2ID],
        T2.column1 AS [C21],
        T2.column2 AS [C22],
        T2.table1id AS [T3ID]
    FROM dbo.Table3 AS T3
        INNER JOIN dbo.Table2 AS T2
        ON T2.id = T3.table2id;
GO

CREATE SEQUENCE [dbo].[Seq1]
AS [INT]
START WITH 38187
INCREMENT BY 1
MINVALUE-2147483648
MAXVALUE 2147483647
CACHE;
GO

CREATE SEQUENCE [dbo].[Seq2]
AS [INT]
START WITH 38187
INCREMENT BY 1
MINVALUE-2147483648
MAXVALUE 2147483647
CACHE;
GO

CREATE SEQUENCE [dbo].[Seq3]
AS [INT]
START WITH 38187
INCREMENT BY 1
MINVALUE-2147483648
MAXVALUE 2147483647
CACHE;
GO

CREATE SEQUENCE [dbo].[Seq4]
AS [INT]
START WITH 38187
INCREMENT BY 1
MINVALUE-2147483648
MAXVALUE 2147483647
CACHE;
GO

CREATE SEQUENCE [dbo].[Seq5]
AS [INT]
START WITH 38187
INCREMENT BY 1
MINVALUE-2147483648
MAXVALUE 2147483647
CACHE;
GO


