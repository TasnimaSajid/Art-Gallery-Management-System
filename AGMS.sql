/* =====================================================================
   ART GALLERY MANAGEMENT SYSTEM
   Database Schema Script (Microsoft SQL Server / T-SQL)
   ---------------------------------------------------------------------
   This script creates the full database schema for the Art Gallery
   Management System, including:
     1. Database creation
     2. Tables (17 entities)
     3. Primary keys, unique constraints & check constraints
     4. Foreign key relationships
     5. Indexes
     6. Stored procedures

   Run this script top-to-bottom in SQL Server Management Studio (SSMS)
   or via sqlcmd against a SQL Server 2019+ instance.
   ===================================================================== */

-- =====================================================================
-- 1. DATABASE CREATION
-- =====================================================================
IF DB_ID(N'ArtGalleryManagementSystem') IS NULL
BEGIN
    CREATE DATABASE ArtGalleryManagementSystem;
END
GO

USE ArtGalleryManagementSystem;
GO

-- =====================================================================
-- 2. TABLES
-- =====================================================================

-- ---------------------------------------------------------------------
-- GALLERY: physical gallery locations
-- ---------------------------------------------------------------------
CREATE TABLE dbo.GALLERY (
    GalleryID    INT IDENTITY(1,1) NOT NULL,
    Name         NVARCHAR(100) NOT NULL,
    Address      NVARCHAR(100) NOT NULL,
    ContactInfo  NVARCHAR(50)  NOT NULL,
    CONSTRAINT PK_GALLERY PRIMARY KEY CLUSTERED (GalleryID),
    CONSTRAINT UQ_GALLERY_Address UNIQUE (Address)
);
GO

-- ---------------------------------------------------------------------
-- _USER: base account for anyone who can log into the system
-- ---------------------------------------------------------------------
CREATE TABLE dbo._USER (
    UserID              INT IDENTITY(1,1) NOT NULL,
    UserName            NVARCHAR(50)  NOT NULL,
    Email               NVARCHAR(100) NOT NULL,
    Password            NVARCHAR(100) NOT NULL,
    RegistrationDate    DATE          NOT NULL,
    VerificationStatus  NVARCHAR(20)  NOT NULL,
    CONSTRAINT PK__USER PRIMARY KEY CLUSTERED (UserID),
    CONSTRAINT UQ__USER_Email UNIQUE (Email),
    CONSTRAINT CK__USER_VerificationStatus
        CHECK (VerificationStatus IN ('Verified', 'Not Verified'))
);
GO

-- ---------------------------------------------------------------------
-- USER_ROLE: role assigned to a user (Admin, Artist, Visitor, Staff)
-- ---------------------------------------------------------------------
CREATE TABLE dbo.USER_ROLE (
    RoleID    INT IDENTITY(1,1) NOT NULL,
    RoleName  NVARCHAR(100) NOT NULL,
    UserID    INT NULL,
    CONSTRAINT PK_USER_ROLE PRIMARY KEY CLUSTERED (RoleID)
);
GO

-- ---------------------------------------------------------------------
-- ADMIN
-- ---------------------------------------------------------------------
CREATE TABLE dbo.ADMIN (
    AdminID    INT IDENTITY(1,1) NOT NULL,
    RoleID     INT NOT NULL,
    AdminRole  NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_ADMIN PRIMARY KEY CLUSTERED (AdminID)
);
GO

-- ---------------------------------------------------------------------
-- ARTIST
-- ---------------------------------------------------------------------
CREATE TABLE dbo.ARTIST (
    ArtistID        INT IDENTITY(1,1) NOT NULL,
    RoleID          INT NOT NULL,
    Biography       NVARCHAR(100) NULL,
    PortfolioLink   NVARCHAR(100) NULL,
    ApprovalStatus  NVARCHAR(20) NOT NULL,
    CONSTRAINT PK_ARTIST PRIMARY KEY CLUSTERED (ArtistID),
    CONSTRAINT CK_ARTIST_ApprovalStatus
        CHECK (ApprovalStatus IN ('Approved', 'Pending', 'Rejected'))
);
GO

-- ---------------------------------------------------------------------
-- VISITOR
-- ---------------------------------------------------------------------
CREATE TABLE dbo.VISITOR (
    VisitorID       INT IDENTITY(1,1) NOT NULL,
    RoleID          INT NOT NULL,
    MembershipType  NVARCHAR(20) NOT NULL,
    CONSTRAINT PK_VISITOR PRIMARY KEY CLUSTERED (VisitorID),
    CONSTRAINT CK_VISITOR_MembershipType
        CHECK (MembershipType IN ('VIP', 'General'))
);
GO

-- ---------------------------------------------------------------------
-- STAFF
-- ---------------------------------------------------------------------
CREATE TABLE dbo.STAFF (
    StaffID     INT IDENTITY(1,1) NOT NULL,
    RoleID      INT NOT NULL,
    StaffRole   NVARCHAR(100) NOT NULL,
    Department  NVARCHAR(100) NOT NULL,
    GalleryID   INT NULL,
    CONSTRAINT PK_STAFF PRIMARY KEY CLUSTERED (StaffID)
);
GO

-- ---------------------------------------------------------------------
-- EVENTS: umbrella event hosted by a gallery (parent of auctions/exhibitions)
-- ---------------------------------------------------------------------
CREATE TABLE dbo.EVENTS (
    EventID      INT IDENTITY(1,1) NOT NULL,
    EventName    NVARCHAR(100) NOT NULL,
    EventDate    DATE NOT NULL,
    Description  NVARCHAR(500) NULL,
    GalleryID    INT NOT NULL,
    CONSTRAINT PK_EVENTS PRIMARY KEY CLUSTERED (EventID)
);
GO

-- ---------------------------------------------------------------------
-- EXHIBITION
-- ---------------------------------------------------------------------
CREATE TABLE dbo.EXHIBITION (
    ExhibitionID  INT IDENTITY(1,1) NOT NULL,
    Theme         NVARCHAR(100) NOT NULL,
    StartDate     DATE NOT NULL,
    EndDate       DATE NOT NULL,
    EventID       INT NOT NULL,
    CONSTRAINT PK_EXHIBITION PRIMARY KEY CLUSTERED (ExhibitionID),
    CONSTRAINT CK_EXHIBITION_Dates CHECK (StartDate <= EndDate)
);
GO

-- ---------------------------------------------------------------------
-- AUCTION
-- ---------------------------------------------------------------------
CREATE TABLE dbo.AUCTION (
    AuctionID      INT IDENTITY(1,1) NOT NULL,
    StartDateTime  DATETIME NOT NULL,
    EndDateTime    DATETIME NOT NULL,
    AccessType     NVARCHAR(20) NOT NULL,
    Status         NVARCHAR(20) NOT NULL,
    EventID        INT NOT NULL,
    CONSTRAINT PK_AUCTION PRIMARY KEY CLUSTERED (AuctionID),
    CONSTRAINT CK_AUCTION_DateTimes CHECK (StartDateTime <= EndDateTime),
    CONSTRAINT CK_AUCTION_AccessType CHECK (AccessType IN ('VIP Access', 'Public')),
    CONSTRAINT CK_AUCTION_Status CHECK (Status IN ('Active', 'Closed'))
);
GO

-- ---------------------------------------------------------------------
-- ARTWORK: each piece belongs to exactly one auction OR one exhibition
-- ---------------------------------------------------------------------
CREATE TABLE dbo.ARTWORK (
    ArtworkID     INT IDENTITY(1,1) NOT NULL,
    Title         NVARCHAR(50) NOT NULL,
    Category      NVARCHAR(50) NOT NULL,
    Price         DECIMAL(10,2) NOT NULL,
    Availability  NVARCHAR(20) NOT NULL,
    Description   NVARCHAR(500) NULL,
    CreationDate  DATE NOT NULL,
    ArtistID      INT NOT NULL,
    AuctionID     INT NULL,
    ExhibitionID  INT NULL,
    CONSTRAINT PK_ARTWORK PRIMARY KEY CLUSTERED (ArtworkID),
    CONSTRAINT CK_ARTWORK_Availability
        CHECK (Availability IN ('Available', 'Exhibited', 'Sold')),
    CONSTRAINT CK_ARTWORK_AuctionOrExhibition
        CHECK (
            (AuctionID IS NULL AND ExhibitionID IS NOT NULL)
            OR (AuctionID IS NOT NULL AND ExhibitionID IS NULL)
        )
);
GO

-- ---------------------------------------------------------------------
-- AUCTION_REQUEST: artist request to enter an artwork into an auction
-- ---------------------------------------------------------------------
CREATE TABLE dbo.AUCTION_REQUEST (
    RequestID       INT IDENTITY(1,1) NOT NULL,
    AuctionType     NVARCHAR(20) NOT NULL,
    RequestDate     DATE NOT NULL,
    ApprovalStatus  NVARCHAR(20) NOT NULL,
    ArtistID        INT NOT NULL,
    ArtworkID       INT NOT NULL,
    StaffID         INT NOT NULL,
    CONSTRAINT PK_AUCTION_REQUEST PRIMARY KEY CLUSTERED (RequestID),
    CONSTRAINT CK_AUCTION_REQUEST_Type CHECK (AuctionType IN ('Online', 'Live')),
    CONSTRAINT CK_AUCTION_REQUEST_Status
        CHECK (ApprovalStatus IN ('Approved', 'Pending', 'Rejected'))
);
GO

-- ---------------------------------------------------------------------
-- BIDS
-- ---------------------------------------------------------------------
CREATE TABLE dbo.BIDS (
    BidID      INT NOT NULL,
    BidAmount  DECIMAL(10,2) NOT NULL,
    BidTime    DATETIME NOT NULL,
    AuctionID  INT NOT NULL,
    UserID     INT NOT NULL,
    CONSTRAINT PK_BIDS PRIMARY KEY CLUSTERED (BidID)
);
GO

-- ---------------------------------------------------------------------
-- BOOKING: a visitor's booking of a gallery visit (real or virtual)
-- ---------------------------------------------------------------------
CREATE TABLE dbo.BOOKING (
    BookingID    INT IDENTITY(1,1) NOT NULL,
    BookingDate  DATE NOT NULL,
    Status       NVARCHAR(20) NOT NULL,
    BookingType  NVARCHAR(20) NOT NULL,
    VisitorID    INT NOT NULL,
    StaffID      INT NOT NULL,
    CONSTRAINT PK_BOOKING PRIMARY KEY CLUSTERED (BookingID),
    CONSTRAINT CK_BOOKING_Status CHECK (Status IN ('Confirmed', 'Canceled')),
    CONSTRAINT CK_BOOKING_Type CHECK (BookingType IN ('Real', 'Virtual'))
);
GO

-- ---------------------------------------------------------------------
-- REAL_VISIT: subtype of BOOKING for in-person visits
-- ---------------------------------------------------------------------
CREATE TABLE dbo.REAL_VISIT (
    BookingID      INT NOT NULL,
    VisitType      NVARCHAR(20) NOT NULL,
    Location       NVARCHAR(200) NOT NULL,
    VisitDateTime  DATETIME NOT NULL,
    Capacity       INT NOT NULL,
    CONSTRAINT PK_REAL_VISIT PRIMARY KEY CLUSTERED (BookingID),
    CONSTRAINT CK_REAL_VISIT_Type CHECK (VisitType IN ('General', 'Private'))
);
GO

-- ---------------------------------------------------------------------
-- VIRTUAL_VISIT: subtype of BOOKING for online visits
-- ---------------------------------------------------------------------
CREATE TABLE dbo.VIRTUAL_VISIT (
    BookingID             INT NOT NULL,
    Link                  NVARCHAR(200) NOT NULL,
    RegistrationDateTime  DATETIME NOT NULL,
    SessionID             NVARCHAR(50) NOT NULL,
    CONSTRAINT PK_VIRTUAL_VISIT PRIMARY KEY CLUSTERED (BookingID)
);
GO

-- ---------------------------------------------------------------------
-- PURCHASE: completed sale of an artwork, either direct or via auction
-- ---------------------------------------------------------------------
CREATE TABLE dbo.PURCHASE (
    PurchaseID      INT IDENTITY(1,1) NOT NULL,
    PurchaseAmount  DECIMAL(10,2) NOT NULL,
    PurchaseDate    DATE NOT NULL,
    SaleType        NVARCHAR(20) NOT NULL,
    AuctionID       INT NOT NULL,
    ArtworkID       INT NOT NULL,
    UserID          INT NOT NULL,
    CONSTRAINT PK_PURCHASE PRIMARY KEY CLUSTERED (PurchaseID),
    CONSTRAINT CK_PURCHASE_SaleType CHECK (SaleType IN ('Direct', 'Auction'))
);
GO

-- =====================================================================
-- 3. FOREIGN KEY RELATIONSHIPS
-- =====================================================================

ALTER TABLE dbo.USER_ROLE
    ADD CONSTRAINT FK_USER_ROLE_USER
    FOREIGN KEY (UserID) REFERENCES dbo._USER (UserID);
GO

ALTER TABLE dbo.ADMIN
    ADD CONSTRAINT FK_ADMIN_USER_ROLE
    FOREIGN KEY (RoleID) REFERENCES dbo.USER_ROLE (RoleID);
GO

ALTER TABLE dbo.ARTIST
    ADD CONSTRAINT FK_ARTIST_USER_ROLE
    FOREIGN KEY (RoleID) REFERENCES dbo.USER_ROLE (RoleID);
GO

ALTER TABLE dbo.VISITOR
    ADD CONSTRAINT FK_VISITOR_USER_ROLE
    FOREIGN KEY (RoleID) REFERENCES dbo.USER_ROLE (RoleID);
GO

ALTER TABLE dbo.STAFF
    ADD CONSTRAINT FK_STAFF_USER_ROLE
    FOREIGN KEY (RoleID) REFERENCES dbo.USER_ROLE (RoleID);
GO

ALTER TABLE dbo.STAFF
    ADD CONSTRAINT FK_STAFF_GALLERY
    FOREIGN KEY (GalleryID) REFERENCES dbo.GALLERY (GalleryID);
GO

ALTER TABLE dbo.EVENTS
    ADD CONSTRAINT FK_EVENTS_GALLERY
    FOREIGN KEY (GalleryID) REFERENCES dbo.GALLERY (GalleryID);
GO

ALTER TABLE dbo.EXHIBITION
    ADD CONSTRAINT FK_EXHIBITION_EVENTS
    FOREIGN KEY (EventID) REFERENCES dbo.EVENTS (EventID);
GO

ALTER TABLE dbo.AUCTION
    ADD CONSTRAINT FK_AUCTION_EVENTS
    FOREIGN KEY (EventID) REFERENCES dbo.EVENTS (EventID);
GO

ALTER TABLE dbo.ARTWORK
    ADD CONSTRAINT FK_ARTWORK_ARTIST
    FOREIGN KEY (ArtistID) REFERENCES dbo.ARTIST (ArtistID);
GO

ALTER TABLE dbo.ARTWORK
    ADD CONSTRAINT FK_ARTWORK_AUCTION
    FOREIGN KEY (AuctionID) REFERENCES dbo.AUCTION (AuctionID);
GO

ALTER TABLE dbo.ARTWORK
    ADD CONSTRAINT FK_ARTWORK_EXHIBITION
    FOREIGN KEY (ExhibitionID) REFERENCES dbo.EXHIBITION (ExhibitionID);
GO

ALTER TABLE dbo.AUCTION_REQUEST
    ADD CONSTRAINT FK_AUCTION_REQUEST_ARTIST
    FOREIGN KEY (ArtistID) REFERENCES dbo.ARTIST (ArtistID);
GO

ALTER TABLE dbo.AUCTION_REQUEST
    ADD CONSTRAINT FK_AUCTION_REQUEST_ARTWORK
    FOREIGN KEY (ArtworkID) REFERENCES dbo.ARTWORK (ArtworkID);
GO

ALTER TABLE dbo.AUCTION_REQUEST
    ADD CONSTRAINT FK_AUCTION_REQUEST_STAFF
    FOREIGN KEY (StaffID) REFERENCES dbo.STAFF (StaffID);
GO

ALTER TABLE dbo.BIDS
    ADD CONSTRAINT FK_BIDS_AUCTION
    FOREIGN KEY (AuctionID) REFERENCES dbo.AUCTION (AuctionID);
GO

ALTER TABLE dbo.BIDS
    ADD CONSTRAINT FK_BIDS_USER
    FOREIGN KEY (UserID) REFERENCES dbo._USER (UserID);
GO

ALTER TABLE dbo.BOOKING
    ADD CONSTRAINT FK_BOOKING_VISITOR
    FOREIGN KEY (VisitorID) REFERENCES dbo.VISITOR (VisitorID);
GO

ALTER TABLE dbo.BOOKING
    ADD CONSTRAINT FK_BOOKING_STAFF
    FOREIGN KEY (StaffID) REFERENCES dbo.STAFF (StaffID);
GO

ALTER TABLE dbo.REAL_VISIT
    ADD CONSTRAINT FK_REAL_VISIT_BOOKING
    FOREIGN KEY (BookingID) REFERENCES dbo.BOOKING (BookingID);
GO

ALTER TABLE dbo.VIRTUAL_VISIT
    ADD CONSTRAINT FK_VIRTUAL_VISIT_BOOKING
    FOREIGN KEY (BookingID) REFERENCES dbo.BOOKING (BookingID);
GO

ALTER TABLE dbo.PURCHASE
    ADD CONSTRAINT FK_PURCHASE_AUCTION
    FOREIGN KEY (AuctionID) REFERENCES dbo.AUCTION (AuctionID);
GO

ALTER TABLE dbo.PURCHASE
    ADD CONSTRAINT FK_PURCHASE_ARTWORK
    FOREIGN KEY (ArtworkID) REFERENCES dbo.ARTWORK (ArtworkID);
GO

ALTER TABLE dbo.PURCHASE
    ADD CONSTRAINT FK_PURCHASE_USER
    FOREIGN KEY (UserID) REFERENCES dbo._USER (UserID);
GO

-- =====================================================================
-- 4. INDEXES
-- =====================================================================

CREATE NONCLUSTERED INDEX IX_BOOKING_BookingDate
    ON dbo.BOOKING (BookingDate);
GO

CREATE NONCLUSTERED INDEX IX_BOOKING_Date_Visitor
    ON dbo.BOOKING (BookingDate, VisitorID);
GO

CREATE NONCLUSTERED INDEX IX_PURCHASE_ArtworkID
    ON dbo.PURCHASE (ArtworkID);
GO

CREATE NONCLUSTERED INDEX IX_REAL_VISIT_BookingID
    ON dbo.REAL_VISIT (BookingID);
GO

CREATE NONCLUSTERED INDEX IX_REAL_VISIT_Location
    ON dbo.REAL_VISIT (Location);
GO

CREATE NONCLUSTERED INDEX IX_VIRTUAL_VISIT_BookingID
    ON dbo.VIRTUAL_VISIT (BookingID);
GO

-- =====================================================================
-- 5. STORED PROCEDURES
-- =====================================================================

-- ---------------------------------------------------------------------
-- Available_Artworks: list artworks currently available for sale
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.Available_Artworks
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ArtworkID, Title, Category, Price
    FROM dbo.ARTWORK
    WHERE Availability = 'Available';
END;
GO

-- ---------------------------------------------------------------------
-- New_Booking: create a confirmed booking for a visitor
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.New_Booking
    @VisitorID    INT,
    @BookingDate  DATE,
    @BookingType  NVARCHAR(20),
    @StaffID      INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.BOOKING (BookingDate, Status, BookingType, VisitorID, StaffID)
    VALUES (@BookingDate, 'Confirmed', @BookingType, @VisitorID, @StaffID);
END;
GO

-- ---------------------------------------------------------------------
-- Place_Bid: record a bid placed on an auction
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.Place_Bid
    @BidID      INT,
    @AuctionID  INT,
    @UserID     INT,
    @BidAmount  DECIMAL(10,2),
    @BidTime    DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.BIDS (BidID, AuctionID, UserID, BidAmount, BidTime)
    VALUES (@BidID, @AuctionID, @UserID, @BidAmount, @BidTime);
END;
GO

-- ---------------------------------------------------------------------
-- Purchase_Report: list purchases within a date range
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.Purchase_Report
    @StartDate  DATE,
    @EndDate    DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        p.PurchaseID,
        p.PurchaseAmount,
        p.PurchaseDate,
        p.SaleType,
        a.Title    AS ArtworkTitle,
        u.UserName AS Buyer
    FROM dbo.PURCHASE p
    JOIN dbo.ARTWORK a ON p.ArtworkID = a.ArtworkID
    JOIN dbo._USER u   ON p.UserID = u.UserID
    WHERE p.PurchaseDate BETWEEN @StartDate AND @EndDate
    ORDER BY p.PurchaseDate;
END;
GO

-- ---------------------------------------------------------------------
-- Update_Exhibition_Schedule: reschedule an exhibition's start/end dates
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.Update_Exhibition_Schedule
    @ExhibitionID  INT,
    @StartDate     DATE,
    @EndDate       DATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.EXHIBITION
    SET StartDate = @StartDate,
        EndDate   = @EndDate
    WHERE ExhibitionID = @ExhibitionID;
END;
GO

/* =====================================================================
   END OF SCRIPT
   ===================================================================== */
