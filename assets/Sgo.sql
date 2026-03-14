CREATE DATABASE TechnicalPlatformDB;
GO
USE TechnicalPlatformDB;
GO
-- جدول المستخدمين الأساسي
CREATE TABLE [User] (
    user_id INT PRIMARY KEY IDENTITY(1,1),
    email NVARCHAR(255) UNIQUE NOT NULL,
    password_hash NVARCHAR(MAX) NOT NULL,
    role NVARCHAR(50) CHECK (role IN ('Admin', 'Technician', 'Company')),
    account_status NVARCHAR(50) DEFAULT 'Pending_Verification',
    created_at DATETIME2 DEFAULT GETDATE()
    
);

-- جدول التصنيفات
CREATE TABLE Category (
    cat_id INT PRIMARY KEY IDENTITY(1,1),
    cat_name NVARCHAR(100) NOT NULL
);

-- جدول التصنيفات الفرعية
CREATE TABLE Sub_Category (
    sub_cat_id INT PRIMARY KEY IDENTITY(1,1),
    cat_id INT FOREIGN KEY REFERENCES CATEGORY(cat_id),
    sub_cat_name NVARCHAR(100) NOT NULL
);

-- بروفايل الأدمن
CREATE TABLE Admin_Profile  (
    admin_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT UNIQUE FOREIGN KEY REFERENCES [User](user_id),
    full_name NVARCHAR(200),
    admin_level NVARCHAR(50) -- SuperAdmin, Moderator
);

-- بروفايل الشركة
CREATE TABLE Company (
    company_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT UNIQUE FOREIGN KEY REFERENCES [USER](user_id),
    name NVARCHAR(200) NOT NULL,
    address NVARCHAR(MAX),
    tax_id NVARCHAR(100) UNIQUE,
    is_verified BIT DEFAULT 0
);

-- بروفايل الفني
CREATE TABLE Technician_Profile ( 
    technician_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT UNIQUE FOREIGN KEY REFERENCES [USER](user_id),
    sub_cat_id INT FOREIGN KEY REFERENCES SUB_CATEGORY(sub_cat_id),
    name NVARCHAR(200),
    phone NVARCHAR(20),
    experience_years INT,
    availability_status NVARCHAR(50) DEFAULT 'Available',
    profile_completion_percentage FLOAT DEFAULT 0
);

-- جدول المهارات
CREATE TABLE Skill (
    skill_id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(100) NOT NULL
);

-- جدول مهارات الفنيين (Many-to-Many)
CREATE TABLE Technician_Skills (
    technician_id INT FOREIGN KEY REFERENCES Technician_Profile(technician_id),
    skill_id INT FOREIGN KEY REFERENCES SKILL(skill_id),
    PRIMARY KEY (technician_id, skill_id)
);

-- جدول الوظائف
CREATE TABLE Job_Vacancy  (
    job_id INT PRIMARY KEY IDENTITY(1,1),
    company_id INT FOREIGN KEY REFERENCES Company(company_id),
    sub_cat_id INT FOREIGN KEY REFERENCES Sub_category(sub_cat_id),
    approved_by_admin_id INT FOREIGN KEY REFERENCES Admin_Profile (admin_id),
    title NVARCHAR(255) NOT NULL,
    description NVARCHAR(MAX),
    salary_range NVARCHAR(100),
    status NVARCHAR(50) DEFAULT 'Pending_Approval',
    created_at DATETIME2 DEFAULT GETDATE()
);

-- جدول طلبات التوظيف
CREATE TABLE  Application (
    app_id INT PRIMARY KEY IDENTITY(1,1),
    technician_id INT FOREIGN KEY REFERENCES Technician_Profile(technician_id),
    job_id INT FOREIGN KEY REFERENCES Job_Vacancy(job_id),
    status NVARCHAR(50) DEFAULT 'Pending',
    match_score FLOAT,
    applied_at DATETIME2 DEFAULT GETDATE()
);
-- جدول المقابلات
CREATE TABLE Interview_Scheduale   (
    interview_id INT PRIMARY KEY IDENTITY(1,1),
    app_id INT FOREIGN KEY REFERENCES Application(app_id),
    scheduled_time DATETIME2,
    meeting_link_or_location NVARCHAR(MAX),
    interview_status NVARCHAR(50) DEFAULT 'Scheduled',
    admin_notes NVARCHAR(MAX)
);

-- سجل التوظيف (عقد)
CREATE TABLE Hire_Record (
    hire_id INT PRIMARY KEY IDENTITY(1,1),
    app_id INT UNIQUE FOREIGN KEY REFERENCES Application(app_id),
    hire_date DATE DEFAULT GETDATE(),
    employment_status NVARCHAR(50) DEFAULT 'Probation'
);

-- الفواتير
CREATE TABLE Platform_Invoice  (
    invoice_id INT PRIMARY KEY IDENTITY(1,1),
    hire_id INT UNIQUE FOREIGN KEY REFERENCES Hire_Record(hire_id),
    company_id INT FOREIGN KEY REFERENCES Company(company_id),
    total_amount DECIMAL(18,2),
    payment_status NVARCHAR(50) DEFAULT 'Pending',
    paid_at DATETIME2
);

-- التقييمات
CREATE TABLE Feedback_Rating(
    feedback_id INT PRIMARY KEY IDENTITY(1,1),
    hire_id INT FOREIGN KEY REFERENCES Hire_Record(hire_id),
    reviewer_id INT FOREIGN KEY REFERENCES [User](user_id),
    target_user_id INT FOREIGN KEY REFERENCES [User](user_id),
    rating_score INT CHECK (rating_score BETWEEN 1 AND 5),
    comment NVARCHAR(MAX),
    created_at DATETIME2 DEFAULT GETDATE()
);
CREATE TABLE Dispute (
    dispute_id INT PRIMARY KEY IDENTITY(1,1),
    hire_id INT FOREIGN KEY REFERENCES Hire_Record(hire_id),
    raised_by_user_id INT FOREIGN KEY REFERENCES [User](user_id),
    handled_by_admin_id INT FOREIGN KEY REFERENCES Admin_Profile(admin_id),
    issue_description NVARCHAR(MAX),
    status NVARCHAR(50) DEFAULT 'Open'
);

CREATE TABLE System_Logs (
    log_id INT PRIMARY KEY IDENTITY(1,1),
    performer_id INT FOREIGN KEY REFERENCES [User](user_id),
    action_type NVARCHAR(100),
    action_details NVARCHAR(MAX),
    timestamp DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE Notification_Log   (
    notif_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT FOREIGN KEY REFERENCES [User](user_id),
    message NVARCHAR(MAX),
    is_read BIT DEFAULT 0,
    sent_at DATETIME2 DEFAULT GETDATE()
);
ALTER TABLE [User] ADD User_Name nvarchar(100);
ALTER TABLE Technician_Profile
ADD ProfilePicture NVARCHAR(MAX) NULL;

CREATE TABLE Verification (
    verification_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT UNIQUE FOREIGN KEY REFERENCES [User](user_id),
    document_type NVARCHAR(100), -- 'National_ID' or 'Commercial_Register'
    document_path NVARCHAR(MAX), -- مسار الصورة
    verification_status NVARCHAR(50) DEFAULT 'Pending',
    uploaded_at DATETIME2 DEFAULT GETDATE(),
    automated_notes NVARCHAR(MAX) -- هنا السيستم يكتب "تم التوثيق تلقائياً"
);
ALTER TABLE Verification 
ADD AiConfidenceScore FLOAT NULL;

-- إضافة عمود الملاحظات وحالة الطلب وتاريخ المعالجة
ALTER TABLE Verification 
ADD AdminNotes NVARCHAR(MAX) NULL,
    Status NVARCHAR(50) DEFAULT 'Pending',
    ProcessedAt DATETIME NULL;
    -- إضافة عمود بوليان (0 أو 1) لتمييز الحساب الموثق
ALTER TABLE [User] 
ADD IsVerified BIT NOT NULL DEFAULT 0;

ALTER TABLE Company
ADD CompanyLogo NVARCHAR(MAX) NULL, -- لتخزين مسار الصورة
    Description NVARCHAR(MAX) NULL; -- لحقل "About Us"


USE TechnicalPlatformDB;
GO

-- 1. إضافة نوع التعاقد وتاريخ الانتهاء لجدول الوظائف
ALTER TABLE Job_Vacancy 
ADD EmploymentType NVARCHAR(50) DEFAULT 'Full-Time',
    ExpiryDate DATETIME2 NULL;

-- 2. إضافة مستوى المهارة في جدول الربط
ALTER TABLE Technician_Skills 
ADD SkillLevel NVARCHAR(50) DEFAULT 'Intermediate'; -- (Beginner, Intermediate, Expert)

-- 3. إضافة ضرائب وعمولة في جدول الفواتير
ALTER TABLE Platform_Invoice 
ADD TaxAmount DECIMAL(18,2) DEFAULT 0,
    PlatformCommission DECIMAL(18,2) DEFAULT 0;

-- 4. إضافة جدول الفنيين المفضلين للشركة
CREATE TABLE Company_Favorites (
    favorite_id INT PRIMARY KEY IDENTITY(1,1),
    company_id INT FOREIGN KEY REFERENCES Company(company_id),
    technician_id INT FOREIGN KEY REFERENCES Technician_Profile(technician_id),
    saved_at DATETIME2 DEFAULT GETDATE()
);
GO

USE TechnicalPlatformDB;
GO

-- حذف الجدول تماماً
IF OBJECT_ID('Company_Favorites', 'U') IS NOT NULL
    DROP TABLE Company_Favorites;
GO