/*
    AUTHOR  : NISHTABYE ITTOO
    PURPOSE : Return details for the SECOND (2nd) highest Order Total Amount.
 */


CREATE OR REPLACE PROCEDURE TEST.GETSECONDHIGHESTORDERAMOUNTPROCEDURE
AS

order_reference VARCHAR2(15);
order_date VARCHAR2(50);
supplier_name VARCHAR(100);
order_total_amount VARCHAR2(15);
order_status VARCHAR2(10);
invoices VARCHAR2(100);
BEGIN

SELECT Order_Reference, ORDER_PERIOD, SUPPLIER_NAME, TOTAL_ORDER_AMOUNT, Order_Status, INVOICE_REFERENCES
INTO order_reference, order_date,supplier_name, order_total_amount, order_status, invoices
FROM (
         SELECT Order_Reference,
                TO_CHAR(MAX(ORDER_PERIOD), 'fmMonth DD, YYYY') AS ORDER_PERIOD,
                MAX(UPPER(SUPPLIER_NAME)) AS SUPPLIER_NAME,
                MAX(ORDER_TOTAL_AMOUNT) AS TOTAL_ORDER_AMOUNT,
                MAX(Order_Status) AS Order_Status,
                ROW_NUMBER() OVER (ORDER BY MAX(ORDER_TOTAL_AMOUNT) DESC) AS row_num,
                 LISTAGG(DISTINCT(INVOICE_REFERENCE), '|') WITHIN GROUP (ORDER BY INVOICE_REFERENCE) AS INVOICE_REFERENCES
         FROM PURCHASE_ORDER_DETAILS_VIEW
         GROUP BY Order_Reference
         ORDER BY TOTAL_ORDER_AMOUNT DESC
     ) WHERE row_num  = 2;


DBMS_OUTPUT.PUT_LINE('The Second Highest Order Detail is displayed below: ');
	DBMS_OUTPUT.PUT_LINE('Order_Reference: ' || order_reference);
	DBMS_OUTPUT.PUT_LINE('ORDER_PERIOD: ' || order_date);
	DBMS_OUTPUT.PUT_LINE('SUPPLIER_NAME: ' || supplier_name);
	DBMS_OUTPUT.PUT_LINE('ORDER_TOTAL_AMOUNT: ' || order_total_amount);
	DBMS_OUTPUT.PUT_LINE('Order_Status: ' || order_status);
	DBMS_OUTPUT.PUT_LINE('INVOICE_REFERENCES: ' || invoices);
END;


--To execute
BEGIN
    TEST.GETSECONDHIGHESTORDERAMOUNTPROCEDURE;
END;

