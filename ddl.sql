DROP TABLE IF EXISTS Currency CASCADE;
DROP TABLE IF EXISTS AvitoUser CASCADE;
DROP TABLE IF EXISTS Auction CASCADE;
DROP TABLE IF EXISTS Bid CASCADE;
DROP TABLE IF EXISTS Sale CASCADE;
DROP TABLE IF EXISTS FeedBack CASCADE;
DROP TABLE IF EXISTS ExchangeRate CASCADE;
DROP TABLE IF EXISTS Wallet CASCADE;
DROP TABLE IF EXISTS TreasuryAccount CASCADE;
DROP TABLE IF EXISTS SaleTx CASCADE;
DROP TABLE IF EXISTS SystemTx CASCADE;

DROP TYPE IF EXISTS AUCTION_STATUS CASCADE;
DROP TYPE IF EXISTS SALE_STATUS CASCADE;


CREATE TYPE AUCTION_STATUS AS ENUM (
  'Open',
  'Closed'
);

CREATE TYPE SALE_STATUS AS ENUM (
  'Delivered',
  'Payed',
  'Unpayed'
);

CREATE TABLE Currency (
  id TEXT,
  PRIMARY KEY (id)
);

CREATE TABLE AvitoUser (
  id           SERIAL,
  email        TEXT,
  pwd_hash     TEXT,
  salt         TEXT,
  reg_date     DATE,
  display_name TEXT,
  PRIMARY KEY (id)
);

CREATE TABLE Auction (
  id            SERIAL,
  desription    TEXT,
  creation_date DATE,
  seller_id     INTEGER,
  status        AUCTION_STATUS,
  currency      TEXT,
  FOREIGN KEY (seller_id) REFERENCES AvitoUser (id),
  FOREIGN KEY (currency) REFERENCES Currency (id),
  PRIMARY KEY (id)
);

CREATE TABLE Bid (
  user_id    INTEGER,
  auction_id INTEGER,
  amount     DECIMAL,
  FOREIGN KEY (auction_id) REFERENCES Auction (id),
  FOREIGN KEY (user_id) REFERENCES AvitoUser (id),
  PRIMARY KEY (user_id, auction_id)
);


CREATE TABLE Sale (
  id         SERIAL,
  buyer_id   INTEGER,
  status     SALE_STATUS,
  user_id    INTEGER,
  auction_id INTEGER,
  FOREIGN KEY (user_id, auction_id) REFERENCES Bid (user_id, auction_id),
  FOREIGN KEY (buyer_id) REFERENCES AvitoUser (id),
  FOREIGN KEY (auction_id) REFERENCES Auction (id),
  PRIMARY KEY (id)
);


CREATE TABLE FeedBack (
  id          SERIAL,
  reviewer_id INTEGER,
  reviewee_id INTEGER,
  score       INTEGER,
  commectary  TEXT,
  FOREIGN KEY (reviewee_id) REFERENCES AvitoUser (id),
  FOREIGN KEY (reviewer_id) REFERENCES AvitoUser (id),
  PRIMARY KEY (id)
);


CREATE TABLE ExchangeRate (
  from_cur TEXT,
  to_cur   TEXT,
  time     TIMESTAMP,
  rate     DECIMAL, /* to/from */
  FOREIGN KEY (from_cur) REFERENCES Currency (id),
  FOREIGN KEY (to_cur) REFERENCES Currency (id),
  PRIMARY KEY (from_cur, to_cur, time)
);

CREATE TABLE Wallet (
  user_id     INTEGER,
  currency_id TEXT,
  amount      DECIMAL,
  FOREIGN KEY (currency_id) REFERENCES Currency (id),
  PRIMARY KEY (user_id, currency_id)
);

CREATE TABLE TreasuryAccount (
  id          SERIAL,
  currency_id TEXT,
  amount      DECIMAL,
  FOREIGN KEY (currency_id) REFERENCES Currency (id),
  PRIMARY KEY (id)
);

CREATE TABLE SaleTx (
  id               SERIAL,
  from_user_id     INTEGER,
  from_currency_id TEXT,
  to_user_id       INTEGER,
  to_currency_id   TEXT,
  sale_id          INTEGER,
  FOREIGN KEY (sale_id) REFERENCES Sale (id),
  FOREIGN KEY (from_user_id, from_currency_id) REFERENCES Wallet (user_id, currency_id),
  FOREIGN KEY (to_user_id, to_currency_id) REFERENCES Wallet (user_id, currency_id),
  PRIMARY KEY (id)
);

CREATE TABLE SystemTx (
  id                  SERIAL,
  treasury_account_id INTEGER,
  user_id             INTEGER,
  currency_id         TEXT,
  amount              DECIMAL,
  FOREIGN KEY (treasury_account_id) REFERENCES TreasuryAccount (id),
  FOREIGN KEY (currency_id) REFERENCES Currency (id),
  FOREIGN KEY (user_id, currency_id) REFERENCES Wallet (user_id, currency_id),
  PRIMARY KEY (id)
);