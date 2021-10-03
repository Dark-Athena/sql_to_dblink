CREATE OR REPLACE FUNCTION SQL_TO_DBLINKSQL_F(l_sql varchar2,DB_LINK VARCHAR2) RETURN VARCHAR2 IS
/*
Copyright DarkAthena(darkathena@qq.com)

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
/*该功能用来转换sql为DBLINK的SQL，
作者 ：DarkAthena
日期：20170128
最后修改日期：20170522  在最后将错误生成的  (@DB_LINK  替换成  （
规范1：不允许使用‘--’注释
    2：FROM后面表的顺序必须是先表后子查询
    3：查询字段允许使用子查询
    4：查询条件中的静态字符串不要有 A.大小写混合，B.大于1个以上的空格，C.回车*/
  str   varchar2(30000);
  str2  varchar2(30000);
  str_a varchar2(30000);
  str_b varchar2(30000);
  str_T varchar2(30000);

  STR2_L NUMBER;
  I      NUMBER;
  J      NUMBER;
  K      NUMBER;

  L NUMBER;
begin
  l    := 0;
 /* str  := 'select (SELECT EEE FROM TTT WHERE T1=456),* from
 (select * from
 taba1 , taba2 b ,TAB3

 ),(select   user_from    from tabfrom

 ) where 1=1
  ';*/
  str  := l_sql;
  str2 := UPPER(str); ---大写
  str2 := replace(str2, chr(10), chr(32)); ---回车转空格
  str2 := replace(str2, chr(9), chr(32)); ---TAB转空格
  str2 := replace(str2, chr(44), chr(32) || chr(44) || chr(32)); ---逗号前面后面加空格
  str2 := replace(str2, chr(40), chr(32) || chr(40) || chr(32)); ---括号前面后面加空格
  str2 := replace(str2, chr(41), chr(32) || chr(41) || chr(32)); ---括号前面后面加空格

  --- STR2_L:=LENGTH(STR2);

  LOOP
    STR2_L := LENGTH(STR2);
    STR2   := REPLACE(STR2, CHR(32) || CHR(32), CHR(32)); ---双空格替换成单空格
    IF STR2_L = LENGTH(STR2) THEN
      EXIT;
    END IF;
  END LOOP;
  I     := 1;
  str_b := STR2;
  --- str_a:=SUBSTR(STR2,1,INSTR(STR2,' FROM ')+5);
  LOOP

    IF (SUBSTR(str2, I, 6) = CHR(32) || 'FROM' || CHR(32) and
       SUBSTR(str2, I + 6, 1) <> chr(40) )---寻找 FROM 关键字 且后面不是左括号

     THEN

      IF L = 0 THEN
        str_a := SUBSTR(STR2, 1, I + 5);  --初始，拼接第一个表前面一截
      END IF;
      if l <> 0 then
        STR_A := STR_A || substr(str2, l - 1, i - l + 1) || CHR(32) ||
                 'FROM' || CHR(32);  ---拼接表和表中间的部分 非逗号
      end if;
      J := 0;
      LOOP
        K := 1;

        LOOP
          IF SUBSTR(STR2, I + 6 + J + K, 1) = CHR(32)

           THEN
            STR_T := SUBSTR(STR2, I + 6 + J, K); ---取表名
            STR_A := STR_A || STR_T || '@'||DB_LINK;
            K     := K + 1;
            EXIT;
          END IF;
          K := K + 1;
        END LOOP;
    /*   dbms_output.put_line('AAA ' || SUBSTR(STR2, I + 6 + J + K, 1));*/

      /*   dbms_output.put_line('AAAA ' || SUBSTR(STR2, I + 6 + J + K+2, 1));*/
        IF SUBSTR(STR2, I + 6 + J + K, 1) = chr(41)
         and  SUBSTR(STR2, I + 6 + J + K+2, 1)<>CHR(44)*/---如果是右括号

         THEN
          l := i + j + k + 6;
          EXIT;
        elsif SUBSTR(STR2, I + 6 + J + K, 1) <> CHR(44) then  --如果不是逗号
        /*  dbms_output.put_line(substr(str2, I + 6 + J + K, 30000));
          dbms_output.put_line(instr(substr(str2, I + 6 + J + K, 30000),
                                     chr(32)));
          dbms_output.put_line(SUBSTR(STR2,
                                      I + 6 + J + K,
                                      instr(substr(str2,
                                                   I + 6 + J + K,
                                                   30000),
                                            chr(32))));*/

          str_a := str_a || chr(32) ||
                   SUBSTR(STR2,
                          I + 6 + J + K - 1,
                          instr(substr(str2, I + 6 + J + K, 30000), chr(32)));--拼接表别名
          k     := k + instr(substr(str2, I + 6 + J + K, 30000), chr(32));
        /*  DBMS_OUTPUT.put_line(SUBSTR(STR2, I + 6 + J + K, 1));
                    DBMS_OUTPUT.put_line( SUBSTR(STR2, I + 6 + J + K + 2, 1));*/

          if SUBSTR(STR2, I + 6 + J + K, 1) <> CHR(44) /*OR
             SUBSTR(STR2, I + 6 + J + K + 2, 1) = CHR(40)*/ then ---如果不是逗号
            l := i + j + k + 6;
            EXIT;

          end if;

        END IF;
        STR_A := STR_A || chr(44);
        J     := J + K + 1;
      END LOOP;

    END IF;

    str_b := SUBSTR(str2, I + 1, 30000);
    IF INSTR(str_b, CHR(32) || 'FROM' || CHR(32)) = 0 THEN
      EXIT;
    END IF;
    I := I + 1;

  END LOOP;
  str_a := str_a || substr(str2, l - 1, 30000);
 --- dbms_output.put_line(str_a);
 str_a:=REPLACE(str_a,'(@'||DB_LINK,'(');
  RETURN str_a;

end;
/
