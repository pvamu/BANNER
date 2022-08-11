/*
Trigger developed to control SBSECT Max Enrollment numbers
This trigger will look at room capacity of the assigned class 
and prevent if max enrollment exceeds it
Created by AFJ @OculusIT June/2022
*/

CREATE OR REPLACE TRIGGER st_ssbsect_max_enrl_trig BEFORE
    UPDATE OF ssbsect_max_enrl ON saturn.ssbsect
    FOR EACH ROW
--referencing old as old new as new 
DECLARE
    a         NUMBER := 0;
    b         NUMBER := 0;
    r_cap     NUMBER := 0;
    bldg_code VARCHAR2(20);
    room_num  VARCHAR2(20);
    res       VARCHAR2(20);
    room_limit_exceed EXCEPTION;
    PRAGMA exception_init ( room_limit_exceed, -20111 );
BEGIN
    SELECT
        COUNT(*)
    INTO a
    FROM
        ssrmeet
    WHERE
            ssrmeet_term_code = :old.ssbsect_term_code
        AND ssrmeet_crn = :old.ssbsect_crn;

    IF a = 1 THEN
        SELECT
            nvl((
                SELECT
                    nvl(ssrmeet_room_code, 'xx')
                FROM
                    ssrmeet
                WHERE
                        ssrmeet_term_code = :old.ssbsect_term_code
                    AND ssrmeet_crn = :old.ssbsect_crn
            ), 'xx') ress
        INTO res
        FROM
            dual;

        IF res = 'xx' THEN
            GOTO here;
        ELSE
            SELECT
                ssrmeet_bldg_code,
                ssrmeet_room_code
            INTO
                bldg_code,
                room_num
            FROM
                ssrmeet
            WHERE
                    ssrmeet_term_code = :old.ssbsect_term_code
                AND ssrmeet_crn = :old.ssbsect_crn;
           --
            SELECT
                slbrdef_capacity
            INTO r_cap
            FROM
                slbrdef a
            WHERE
                    slbrdef_bldg_code = bldg_code
                AND slbrdef_room_number = room_num
                AND slbrdef_term_code_eff = (
                    SELECT
                        MAX(slbrdef_term_code_eff)
                    FROM
                        slbrdef b
                    WHERE
                            b.slbrdef_bldg_code = a.slbrdef_bldg_code
                        AND b.slbrdef_room_number = a.slbrdef_room_number
                );

        END IF;

    ELSE
        GOTO here;
    END IF;

    IF :new.ssbsect_max_enrl > r_cap THEN
        raise_application_error(-20111, 'Max Enrollment exceeds room capacity, check room assignment');
    END IF;

    << here >> NULL;
END;