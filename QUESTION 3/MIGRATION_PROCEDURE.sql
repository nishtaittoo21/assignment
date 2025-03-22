CREATE OR REPLACE PROCEDURE Migratedataforbcm
AS
  CURSOR data_cursor IS
SELECT order_ref,
       order_date,
       supplier_name,
       supp_contact_name,
       supp_address,
       supp_contact_number,
       supp_email,
       order_total_amount,
       order_description,
       order_status,
       order_line_amount,
       invoice_reference,
       invoice_date,
       invoice_status,
       invoice_hold_reason,
       invoice_amount,
       invoice_description
FROM   xxbcm_order_mgt;
contact_numbers           VARCHAR2(50);
  first_number              VARCHAR2(50);
  second_number             VARCHAR2(50);
  mobile_number             VARCHAR2(50);
  phone_number              VARCHAR2(50);
  v_count                   INTEGER;
  order_count               INTEGER;
  supplier_id               NUMBER;
  order_line_count          INTEGER;
  cleaned_order_line_amount VARCHAR2(50);
  order_line_id             NUMBER;
  cleaned_invoice_amount VARCHAR2(50);
  counter_order_line_details INTEGER;
BEGIN
FOR rec IN data_cursor LOOP
            dbms_output.Put_line('rec: '
                                 || rec.order_ref);

            contact_numbers := rec.supp_contact_number;

            IF Instr(contact_numbers, ',') > 0 THEN
              first_number := Trim(Regexp_substr(contact_numbers, '[^,]+', 1, 1));

              second_number := Trim(Regexp_substr(contact_numbers, '[^,]+', 1, 2));

                IF first_number LIKE '5%' THEN
                    mobile_number := first_number;
                    phone_number := second_number;
ELSE
                    mobile_number := second_number;
                    phone_number := first_number;
END IF;
            ELSIF contact_numbers LIKE '5%' THEN
              mobile_number := contact_numbers;
              phone_number := NULL;
ELSE
              phone_number := contact_numbers;
              mobile_number := NULL;
END IF;

SELECT Count(*)
INTO   v_count
FROM   supplier_data
WHERE  supplier_name = rec.supplier_name
  AND supp_contact_name = rec.supp_contact_name;

IF v_count = 0 THEN
              INSERT INTO supplier_data
                          (supplier_name,
                           supp_contact_name,
                           supp_address,
                           supp_mobile_number,
                           supp_phone_number,
                           supp_email)
              VALUES      (rec.supplier_name,
                           rec.supp_contact_name,
                           rec.supp_address,
                           mobile_number,
                           phone_number,
                           rec.supp_email);
END IF;

            -- Insert into ORDER_SUMMARY if order is not found
    IF rec.order_total_amount IS NOT NULL AND Length(rec.order_ref) = 5 THEN
SELECT Count(*)
INTO   order_count
FROM   order_summary
WHERE  order_ref = rec.order_ref;

SELECT supplier_id
INTO   supplier_id
FROM   supplier_data
WHERE  supplier_name = rec.supplier_name
  AND supp_contact_name = rec.supp_contact_name;

IF order_count = 0 THEN
                    INSERT INTO order_summary
                                (order_ref,
                                 order_date,
                                 supplier_id,
                                 order_total_amount,
                                 order_description,
                                 order_status)
                    VALUES      (rec.order_ref,
                                 To_date(rec.order_date, 'DD/MM/YYYY'),
                                 supplier_id,
                                 To_number(Replace(rec.order_total_amount, ',', '')),
                                 rec.order_description,
                                 rec.order_status);
END IF;
END IF;


    IF Length(rec.order_ref) > 5 THEN

      -- Assuming ORDER_REF is a string, start from position 5 of the string
          cleaned_order_line_amount := CASE
                                         WHEN
          Instr(rec.order_line_amount, 'S') > 0
                                       THEN
                                         Replace(rec.order_line_amount, 'S', '5'
                                         )
                                         WHEN
          Instr(rec.order_line_amount, 'o') > 0
                                       THEN
                                         Replace(rec.order_line_amount, 'o', '0'
                                         )
                                         WHEN
          Instr(rec.order_line_amount, 'I') > 0
                                       THEN
                                         Replace(rec.order_line_amount, 'I', '1'
                                         )
                                         ELSE rec.order_line_amount
END;


         cleaned_invoice_amount := CASE
                                         WHEN
          Instr(rec.INVOICE_AMOUNT, 'S') > 0
                                       THEN
                                         Replace(rec.order_line_amount, 'S', '5'
                                         )
                                         WHEN
          Instr(rec.INVOICE_AMOUNT, 'o') > 0
                                       THEN
                                         Replace(rec.order_line_amount, 'o', '0'
                                         )
                                         WHEN
          Instr(rec.INVOICE_AMOUNT, 'I') > 0
                                       THEN
                                         Replace(rec.order_line_amount, 'I', '1'
                                         )
                                         ELSE rec.INVOICE_AMOUNT
END;


SELECT Count(*)
INTO   counter_order_line_details
FROM   order_line_details
WHERE  ORDER_REF = rec.ORDER_REF
  AND ORDER_DESCRIPTION = rec.ORDER_DESCRIPTION
  AND ORDER_LINE_AMOUNT = To_number(Replace(cleaned_order_line_amount, ',', ''));

IF counter_order_line_details = 0 THEN
        INSERT INTO order_line_details
        (order_ref,
         order_parent_ref,
         order_description,
         order_status,
         order_line_amount)
        VALUES      (rec.order_ref,
                     Substr(rec.order_ref, 1, 5),
                     rec.order_description,
                     rec.order_status,
                     To_number(Replace(cleaned_order_line_amount, ',', '')));

     IF rec.INVOICE_REFERENCE IS NOT NULL THEN
SELECT ORDER_LINE_ID
INTO order_line_id
FROM TEST.ORDER_LINE_DETAILS
WHERE ORDER_REF = rec.ORDER_REF
  AND ORDER_DESCRIPTION = rec.ORDER_DESCRIPTION
  AND ORDER_LINE_AMOUNT = To_number(Replace(cleaned_order_line_amount, ',', ''));

DBMS_OUTPUT.PUT_LINE('order_line_id' || order_line_id);
INSERT INTO TEST.INVOICE_PAYMENT (INVOICE_REFERENCE, ORDER_LINE_ID, INVOICE_DATE, INVOICE_STATUS, INVOICE_HOLD_REASON, INVOICE_AMOUNT, INVOICE_DESCRIPTION)
VALUES(rec.INVOICE_REFERENCE, order_line_id,   To_date(rec.INVOICE_DATE, 'DD/MM/YYYY'), rec.INVOICE_STATUS, rec.INVOICE_HOLD_REASON, To_number(Replace(cleaned_invoice_amount, ',', '')), rec.INVOICE_DESCRIPTION);
END IF;
END IF;
END IF;

    DBMS_OUTPUT.PUT_LINE('order_line_id' || rec.order_ref || ' ' || rec.order_description);




END LOOP;
END;

BEGIN
    TEST.MigrateDataForBCM;
END;