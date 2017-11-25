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
  creation_date TIMESTAMP,
  seller_id     INTEGER,
  status        AUCTION_STATUS,
  currency      TEXT,
  start_price   DECIMAL,
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
  status     SALE_STATUS,
  user_id    INTEGER,
  auction_id INTEGER,
  FOREIGN KEY (user_id, auction_id) REFERENCES Bid (user_id, auction_id),
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
  id           SERIAL,
  from_user_id INTEGER,
  to_user_id   INTEGER,
  currency_id  TEXT,
  sale_id      INTEGER,
  FOREIGN KEY (sale_id) REFERENCES Sale (id),
  FOREIGN KEY (from_user_id, currency_id) REFERENCES Wallet (user_id, currency_id),
  FOREIGN KEY (to_user_id, currency_id) REFERENCES Wallet (user_id, currency_id),
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

/*
  Когда в SysTx прилетает транзакция, то обновляется также и наши колеьки,
  и кошельки пользоватлелей
 */
CREATE OR REPLACE FUNCTION system_update_balance()
  RETURNS TRIGGER AS
$BODY$
BEGIN
  UPDATE TreasuryAccount
  SET amount = amount + new.amount
  WHERE TreasuryAccount.id = new.treasury_account_id;

  UPDATE Wallet
  SET amount = amount + new.amount
  WHERE Wallet.user_id = new.user_id AND currency_id = new.currency_id;


  RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;

CREATE TRIGGER system_balance
AFTER INSERT ON SystemTx
FOR EACH ROW EXECUTE PROCEDURE system_update_balance();


/*
  Когда в SaleTx прилетает транзакция, то обновляется также и кошельки пользователей
 */
CREATE OR REPLACE FUNCTION sale_update_balance()
  RETURNS TRIGGER AS
$BODY$
DECLARE sale_amount DECIMAL;
BEGIN

  sale_amount :=(
    SELECT amount
    FROM
      Sale
      JOIN bid ON Sale.user_id = Bid.user_id AND Sale.auction_id = Bid.auction_id
    WHERE Sale.id = new.sale_id
  );

  UPDATE Wallet
  SET amount = amount - sale_amount
  WHERE Wallet.user_id = new.from_user_id AND currency_id = new.currency_id;

  UPDATE Wallet
  SET amount = amount + sale_amount
  WHERE Wallet.user_id = new.to_user_id AND currency_id = new.currency_id;


  RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;

CREATE TRIGGER sale_balance
AFTER INSERT ON SaleTx
FOR EACH ROW EXECUTE PROCEDURE sale_update_balance();


/*
  При создании юзреа создаются 3 кошелька
 */
CREATE OR REPLACE FUNCTION new_user_wallets_creation()
  RETURNS TRIGGER AS
$BODY$
DECLARE cur_id TEXT;
BEGIN
  FOR cur_id IN
  SELECT c.id
  FROM Currency c
  LOOP
    INSERT INTO Wallet VALUES (new.id, cur_id, 0);
  END LOOP;

  RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;

CREATE TRIGGER user_wallets_auto_creator
AFTER INSERT ON AvitoUser
FOR EACH ROW EXECUTE PROCEDURE new_user_wallets_creation();

INSERT INTO currency VALUES ('USD');
INSERT INTO currency VALUES ('RUB');
INSERT INTO currency VALUES ('BYN');

INSERT INTO avitouser VALUES (DEFAULT, 'iliagulkov@sobaka.ru', 'kek', 'lol', '2001-10-05', 'huilo');
INSERT INTO avitouser VALUES (DEFAULT, 'drankov@sobaka.ru', 'kek', 'lol', '2002-11-05', 'dranik');
INSERT INTO avitouser VALUES (DEFAULT, 'kashina@sobaka.ru', 'kek', 'lol', '2017-10-05', 'kasha');

INSERT INTO auction VALUES (DEFAULT, 'каша с маслом', '2017-12-31', 3, 'Open', 'RUB', 15);
INSERT INTO auction VALUES (DEFAULT, 'макбук 12 года ', '2017-12-31', 1, 'Open', 'USD', 20);
INSERT INTO auction VALUES (DEFAULT, 'старый макбук из яндекса', '2017-11-20', 2, 'Closed', 'USD', 500);

INSERT INTO bid VALUES (1, 2, 600);
INSERT INTO bid VALUES (1, 1, 228);
INSERT INTO bid VALUES (2, 2, 700);
INSERT INTO bid VALUES (3, 2, 800);
INSERT INTO bid VALUES (1, 3, 1000000);

INSERT INTO sale VALUES (DEFAULT, 'Payed', 1, 1);

INSERT INTO feedback VALUES (DEFAULT, 2, 3, 3, 'каша была невкусная');
INSERT INTO feedback VALUES (DEFAULT, 2, 3, 7, 'каша была невкусная');
INSERT INTO feedback VALUES (DEFAULT, 1, 3, 8, 'каша была невкусная');
INSERT INTO feedback VALUES (DEFAULT, 1, 3, 1, 'каша была невкусная');
INSERT INTO feedback VALUES (DEFAULT, 1, 3, 1, 'каша была невкусная');
INSERT INTO feedback VALUES (DEFAULT, 1, 3, 2, 'каша была невкусная');
INSERT INTO feedback VALUES (DEFAULT, 3, 1, 10, 'каша была вкусная');

INSERT INTO exchangerate VALUES ('RUB', 'BYN', '2017-09-28 01:00:11', 30);
INSERT INTO exchangerate VALUES ('RUB', 'BYN', '2017-09-28 01:20:11', 40);
INSERT INTO exchangerate VALUES ('RUB', 'BYN', '2017-09-28 01:30:11', 50);

INSERT INTO treasuryaccount VALUES (DEFAULT, 'USD', 0);
INSERT INTO treasuryaccount VALUES (DEFAULT, 'RUB', 0);
INSERT INTO treasuryaccount VALUES (DEFAULT, 'BYN', 0);

INSERT INTO systemtx VALUES (DEFAULT, 1, 1, 'USD', 50);

INSERT INTO saletx VALUES (DEFAULT, 1, 3, 'USD', 1);