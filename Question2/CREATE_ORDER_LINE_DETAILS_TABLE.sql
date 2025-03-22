CREATE TABLE ORDER_LINE_DETAILS(
                                   ORDER_LINE_ID INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
                                   ORDER_REF VARCHAR2(7) NOT NULL,
                                   ORDER_PARENT_REF VARCHAR2(5) NOT NULL, CONSTRAINT fk_order_ref FOREIGN KEY (ORDER_PARENT_REF) REFERENCES ORDER_SUMMARY(ORDER_REF),
                                   ORDER_DESCRIPTION VARCHAR2(100) NOT NULL,
                                   ORDER_STATUS VARCHAR2(10)  NOT NULL CONSTRAINT chk_order_line_staus CHECK (ORDER_STATUS IN ('Received', 'Cancelled')),
                                   ORDER_LINE_AMOUNT NUMBER(20) NOT NULL,
                                  // INVOICE_REF VARCHAR2(10) ,CONSTRAINT fk_invoice FOREIGN KEY (INVOICE_REF) REFERENCES INVOICE_DATA(INVOICE_REFERENCE)
);