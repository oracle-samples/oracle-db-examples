/*
PL/SQL doesn't offer native support for multi-dimensional arrays, 
as you will find in other programming languages. You can, however, 
emulate these structures using nested collections. The syntax can be 
something of a surprise to developers, so be sure to hide the details 
behind a simple API.
*/

-- Helper Procedure to Display Booleans
CREATE OR REPLACE PROCEDURE bpl (val IN BOOLEAN) 
IS 
BEGIN 
   DBMS_OUTPUT.put_line ( 
      CASE val 
         WHEN TRUE THEN 'TRUE' 
         WHEN FALSE THEN 'FALSE' 
         ELSE 'NULL' 
      END); 
END bpl; 
/

-- Define Three Level Nested Collection for 3D Array
/*
Dimension 3 is a collection of Dimension 2. Dimension 2 is a collection 
of Dimension 1. It's awkward and it can be even more awkward to remember 
the order in which to reference the dimensions, so we add an API to set 
and get cell values. 
*/

CREATE OR REPLACE PACKAGE multdim AUTHID DEFINER  
IS  
   -- In other languages: l_space array (3, 5, 100);  
     
   TYPE dim1_t IS TABLE OF VARCHAR2 (32767) INDEX BY PLS_INTEGER;  
  
   TYPE dim2_t IS TABLE OF dim1_t INDEX BY PLS_INTEGER;  
  
   TYPE dim3_t IS TABLE OF dim2_t INDEX BY PLS_INTEGER;  
  
   PROCEDURE setcell (  
      array_in   IN OUT   dim3_t  
     ,dim1_in             PLS_INTEGER  
     ,dim2_in             PLS_INTEGER  
     ,dim3_in             PLS_INTEGER  
     ,value_in   IN       VARCHAR2  
   );  
  
   FUNCTION getcell (  
      array_in   IN   dim3_t  
     ,dim1_in         PLS_INTEGER  
     ,dim2_in         PLS_INTEGER  
     ,dim3_in         PLS_INTEGER  
   )  
      RETURN VARCHAR2;  
  
   FUNCTION EXISTS (  
      array_in   IN   dim3_t  
     ,dim1_in         PLS_INTEGER  
     ,dim2_in         PLS_INTEGER  
     ,dim3_in         PLS_INTEGER  
   )  
      RETURN BOOLEAN;  
END multdim; 
/

-- Hide the Details
-- Are you going to remember - are you going to trust others to remember - 
-- the right order in which to specify the dimensions? No!
CREATE OR REPLACE PACKAGE BODY multdim  
IS  
   PROCEDURE setcell (  
      array_in   IN OUT   dim3_t  
     ,dim1_in             PLS_INTEGER  
     ,dim2_in             PLS_INTEGER  
     ,dim3_in             PLS_INTEGER  
     ,value_in   IN       VARCHAR2  
   )  
   IS  
   BEGIN  
      -- Typical syntax: array_in (dim1_in, dim2_in, dim3_in) := value_in;        
        
      array_in (dim3_in) (dim2_in) (dim1_in) := value_in;  
        
      -- Or is it? array_in (dim1_in) (dim2_in) (dim3_in) := value_in;  
   END;  
  
   FUNCTION getcell (  
      array_in   IN   dim3_t  
     ,dim1_in         PLS_INTEGER  
     ,dim2_in         PLS_INTEGER  
     ,dim3_in         PLS_INTEGER  
   )  
      RETURN VARCHAR2  
   IS  
   BEGIN  
      RETURN array_in (dim3_in) (dim2_in) (dim1_in);  
   END;  
  
   FUNCTION EXISTS (  
      array_in   IN   dim3_t  
     ,dim1_in         PLS_INTEGER  
     ,dim2_in         PLS_INTEGER  
     ,dim3_in         PLS_INTEGER  
   )  
      RETURN BOOLEAN  
   IS  
      l_value   VARCHAR2 (32767);  
   BEGIN  
       -- 11/2002 Manchester  
       -- The value doesn't matter; what matters is whether  
       -- this combination exists or not.  
      --  
      -- 02/2003 NWOUG Seattle  
      -- Note: EXISTS method only applies to a single  
      --       collection at a time.  
  
      /*  
      IF array_in(dim3_in )(dim2_in )(dim1_in) IS NOT NULL  
       THEN  
         RETURN TRUE;  
       ELSE  
         RETURN TRUE;  
       END IF;  
       */  
  
      -- Disney World approach 4/2003  
      l_value := array_in (dim3_in) (dim2_in) (dim1_in);  
      RETURN TRUE;  
   EXCEPTION  
      WHEN NO_DATA_FOUND OR VALUE_ERROR  
      THEN  
         RETURN FALSE;  
   END;  
END multdim; 
/

-- Exercise the Package
DECLARE 
   my_3d_array   multdim.dim3_t; 
BEGIN 
   multdim.setcell (my_3d_array, 1, 5, 800, 'def'); 
   multdim.setcell (my_3d_array, 1, 15, 800, 'def'); 
   multdim.setcell (my_3d_array, 5, 5, 800, 'def'); 
   multdim.setcell (my_3d_array, 5, 5, 805, 'def'); 
    
   DBMS_OUTPUT.PUT_LINE (multdim.getcell (my_3d_array, 1, 5, 800)); 
   bpl (multdim.EXISTS (my_3d_array, 1, 5, 800)); 
   bpl (multdim.EXISTS (my_3d_array, 6000, 5, 800)); 
   bpl (multdim.EXISTS (my_3d_array, 6000, 5, 807)); 
    
   DBMS_OUTPUT.PUT_LINE (my_3d_array.COUNT); 
END; 
/

