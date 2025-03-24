/*
    AUTHOR  : NISHTABYE ITTOO
    PURPOSE : To summary of Orders with their corresponding list of distinct invoices and their total amount.
 */


CREATE OR REPLACE PROCEDURE TEST.GETPURCHASEORDERDETAILSPROCEDURE
AS
    CURSOR data_cursor IS
SELECT
    ORDER_REFERENCE,
    ORDER_PERIOD,
    SUPPLIER_NAME,
    ORDER_TOTAL_AMOUNT,
    ORDER_STATUS,
    INVOICE_REFERENCE,
    INVOICE_AMOUNT,
    INVOICE_STATUS
FROM PURCHASE_ORDER_DETAILS_VIEW;

count_temporary_table INTEGER;
    order_reference VARCHAR2(15);
    invoice_reference VARCHAR2(15);
    count_po_with_same_invoice INTEGER;
    invoice_total_amount NUMBER;
    count_status_paid INTEGER;
    count_status_pending INTEGER;
    order_action VARCHAR2(20);
    record_count_in_temp_po INTEGER;

BEGIN
    -- Check if there are records in TEMP_PURCHASE_ORDERS_INVOICES, and delete if any
SELECT count(*)
INTO count_temporary_table
FROM REPORT_PURCHASE_ORDERS_INVOICES;

IF count_temporary_table > 0 THEN
DELETE FROM REPORT_PURCHASE_ORDERS_INVOICES;
END IF;

   DBMS_OUTPUT.PUT_LINE('Only Start deletion');
    -- Loop through data_cursor
FOR rec IN data_cursor LOOP
        order_reference := rec.ORDER_REFERENCE;
        invoice_reference := rec.INVOICE_REFERENCE;

        -- Check if record exists in TEMP_PURCHASE_ORDERS_INVOICES
SELECT count(*)
INTO record_count_in_temp_po
FROM REPORT_PURCHASE_ORDERS_INVOICES
WHERE ORDER_REFERENCE = rec.ORDER_REFERENCE
  AND INVOICE_REFERENCE = rec.INVOICE_REFERENCE;

-- If record does not exist in temporary table, process it
IF record_count_in_temp_po = 0 THEN
            -- Count how many purchase orders are linked to this invoice
SELECT count(*)
INTO count_po_with_same_invoice
FROM PURCHASE_ORDER_DETAILS_VIEW
WHERE ORDER_REFERENCE = rec.ORDER_REFERENCE
  AND INVOICE_REFERENCE = rec.INVOICE_REFERENCE;

-- Count how many are marked as "Paid"
SELECT COUNT(*)
INTO count_status_paid
FROM PURCHASE_ORDER_DETAILS_VIEW
WHERE ORDER_REFERENCE = rec.ORDER_REFERENCE
  AND INVOICE_REFERENCE = rec.INVOICE_REFERENCE
  AND INVOICE_STATUS = 'Paid';

DBMS_OUTPUT.PUT_LINE('For ref ' || rec.ORDER_REFERENCE || ' total count is ' || count_po_with_same_invoice || 'status paid is: ' || count_status_paid);

                -- Determine order action based on paid status
                IF count_status_paid = count_po_with_same_invoice THEN
                    order_action := 'OK';
ELSE
                    -- Count how many are marked as "Pending"
SELECT COUNT(*)
INTO count_status_pending
FROM PURCHASE_ORDER_DETAILS_VIEW
WHERE ORDER_REFERENCE = rec.ORDER_REFERENCE
  AND INVOICE_REFERENCE = rec.INVOICE_REFERENCE
  AND INVOICE_STATUS = 'Pending';

-- Set action based on pending status
IF count_status_pending > 0 THEN
                        order_action := 'To follow up';
ELSE
                        order_action := 'To verify';
END IF;
END IF;

            IF count_po_with_same_invoice > 1 THEN
                -- Sum the total invoice amount for the given order and invoice
SELECT SUM(TO_NUMBER(REPLACE(INVOICE_AMOUNT, ',', '')))
INTO invoice_total_amount
FROM PURCHASE_ORDER_DETAILS_VIEW
WHERE ORDER_REFERENCE = rec.ORDER_REFERENCE
  AND INVOICE_REFERENCE = rec.INVOICE_REFERENCE;



DBMS_OUTPUT.PUT_LINE('invoice_total_amount :' || invoice_total_amount || 'order_action' || order_action);
                -- Insert the processed record into the temporary table
INSERT INTO REPORT_PURCHASE_ORDERS_INVOICES (ORDER_REFERENCE, ORDER_PERIOD, SUPPLIER_NAME, ORDER_TOTAL_AMOUNT, ORDER_STATUS, INVOICE_REFERENCE, INVOICE_TOTAL_AMOUNT, "ACTION")
VALUES (rec.ORDER_REFERENCE, TO_CHAR(rec.ORDER_PERIOD, 'MON-YYYY'), rec.SUPPLIER_NAME, rec.ORDER_TOTAL_AMOUNT, rec.ORDER_STATUS, rec.INVOICE_REFERENCE, TO_CHAR(invoice_total_amount , '9,999,999.00'), order_action);

DBMS_OUTPUT.PUT_LINE('rec.ORDER_REFERENCE inserted:' || rec.ORDER_REFERENCE);

ELSE
                INSERT INTO REPORT_PURCHASE_ORDERS_INVOICES (ORDER_REFERENCE, ORDER_PERIOD, SUPPLIER_NAME, ORDER_TOTAL_AMOUNT, ORDER_STATUS, INVOICE_REFERENCE, INVOICE_TOTAL_AMOUNT, "ACTION")
                VALUES (rec.ORDER_REFERENCE, TO_CHAR(rec.ORDER_PERIOD, 'MON-YYYY'), rec.SUPPLIER_NAME, rec.ORDER_TOTAL_AMOUNT, rec.ORDER_STATUS, rec.INVOICE_REFERENCE, TO_CHAR(rec.INVOICE_AMOUNT , '9,999,999.00'), order_action);
END IF;
END IF;
END LOOP;

END;


-- To execute the procedure
BEGIN
    TEST.GETPURCHASEORDERDETAILSPROCEDURE;
END;