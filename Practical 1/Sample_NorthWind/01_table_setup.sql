/*
drop table 
drop table customers;
drop table suppliers;
drop table shippers;
drop table employees;
drop table products;
drop table categories;
drop table orders;
drop table order_details;
*/

CREATE TABLE Customers (
  CustomerID   VARCHAR(5) NOT NULL, 
  CompanyName  VARCHAR(40) NOT NULL, 
  ContactName  VARCHAR(30), 
  ContactTitle VARCHAR(30), 
  City         VARCHAR(15), 
  Region       VARCHAR(15), 
  PostalCode   VARCHAR(10), 
  Country      VARCHAR(15), 
  PRIMARY KEY (CustomerID)
);

CREATE TABLE Employees (
  EmployeeID number not null, 
  LastName   VARCHAR(20) NOT NULL, 
  FirstName  VARCHAR(10) NOT NULL, 
  Title      VARCHAR(30), 
  BirthDate  DATE, 
  HireDate   DATE, 
  City       VARCHAR(15), 
  Region     VARCHAR(15), 
  PostalCode VARCHAR(10), 
  Country    VARCHAR(15), 
  ReportsTo  number, 
  PRIMARY KEY (EmployeeID)
);

CREATE TABLE Categories (
  CategoryID   number not null, 
  CategoryName VARCHAR(15) UNIQUE NOT NULL, 
  Description  VARCHAR(100), 
  PRIMARY KEY (CategoryID)
);

CREATE TABLE Suppliers (
  SupplierID   number NOT NULL, 
  CompanyName  VARCHAR(40) NOT NULL, 
  ContactName  VARCHAR(30), 
  ContactTitle VARCHAR(30), 
  City         VARCHAR(15), 
  Region       VARCHAR(15), 
  PostalCode   VARCHAR(10), 
  Country      VARCHAR(15), 
  PRIMARY KEY (SupplierID)
);

CREATE TABLE Products (
  ProductID       number NOT NULL, 
  ProductName     VARCHAR(40) NOT NULL, 
  SupplierID      number, 
  CategoryID      number, 
  QuantityPerUnit VARCHAR(20), 
  UnitPrice       number(6,2) DEFAULT 0, 
  UnitsInStock    number DEFAULT 0, 
  UnitsOnOrder    number DEFAULT 0, 
  ReorderLevel    number DEFAULT 0, 
  Discontinued    number(1) DEFAULT 0, 
  PRIMARY KEY (ProductID),
  constraint FK_CategoryID  FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID),
  constraint FK_SupplierID  FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID) 
);

CREATE TABLE Shippers (
  ShipperID   number NOT NULL, 
  CompanyName VARCHAR(40) NOT NULL, 
  Phone       VARCHAR(24), 
  PRIMARY KEY (ShipperID)
);

CREATE TABLE Orders (
  OrderID      number NOT NULL, 
  CustomerID   VARCHAR(5), 
  EmployeeID   number, 
  OrderDate    DATE, 
  RequiredDate DATE, 
  ShippedDate  DATE, 
  ShipVia      number, 
  Freight      number(6,2) DEFAULT 0, 
  PRIMARY KEY (OrderID),
  constraint FK_ShipperID  FOREIGN KEY (ShipVia)    REFERENCES Shippers(ShipperID),
  constraint FK_EmployeeID FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);

CREATE TABLE Order_Details (
  OrderID    number NOT NULL, 
  ProductID  number NOT NULL, 
  UnitPrice  number(6,2) DEFAULT 0, 
  Quantity   number DEFAULT 1, 
  Discount   number(3,2) DEFAULT 0, 
  PRIMARY KEY (OrderID, ProductID),
  constraint FK_OrderID   FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
  constraint FK_ProductID FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);







