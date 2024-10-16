USE [SANKHYA_PROD]
GO
/****** Object:  StoredProcedure [sankhya].[EVE_AD_CALCULAR_TFPVAL]    Script Date: 11/10/2024 14:59:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* Runtime-info
Application: CadastroTelasAdicionais
Referer: https://skw.institutodds.org/mge/flex/CadastroTelasAdicionais.swf/[[DYNAMIC]]/3
ResourceID: br.com.sankhya.core.cfg.DicionarioDados
service-name: AcaoProgramadaSP.createStoredProcedure
uri: /mge/service.sbr
*/
ALTER PROCEDURE [sankhya].[EVE_AD_CALCULAR_TFPVAL] (
       @P_CODUSU INT,                -- Código do usuário logado
       @P_IDSESSAO VARCHAR(4000),    -- Identificador da execução. Serve para buscar informações dos parâmetros/campos da execução.
       @P_QTDLINHAS INT,             -- Informa a quantidade de registros selecionados no momento da execução.
       @P_MENSAGEM VARCHAR(4000) OUT -- Caso seja passada uma mensagem aqui, ela será exibida como uma informação ao usuário.
) AS
DECLARE
       @PARAM_REFORIG DATETIME,
       @PARAM_REFDEST DATETIME,
       @PARAM_CODDEP VARCHAR(4000),
       @PARAM_TIPADO VARCHAR(4000),
       @FIELD_CODEMP INT,
       @FIELD_CODFUNC INT,
       @FIELD_CODLINHA INT,
       @FIELD_REFERENCIA DATETIME,
       @I INT
BEGIN

       -- Os valores informados pelo formulário de parâmetros, podem ser obtidos com as funções:
       --     ACT_INT_PARAM
       --     ACT_DEC_PARAM
       --     ACT_TXT_PARAM
       --     ACT_DTA_PARAM
       -- Estas funções recebem 2 argumentos:
       --     ID DA SESSÃO - Identificador da execução (Obtido através de P_IDSESSAO))
       --     NOME DO PARAMETRO - Determina qual parametro deve se deseja obter.

       SET @PARAM_REFORIG = sankhya.ACT_DTA_PARAM(@P_IDSESSAO, 'REFORIG')
       SET @PARAM_REFDEST = sankhya.ACT_DTA_PARAM(@P_IDSESSAO, 'REFDEST')
       SET @PARAM_CODDEP = sankhya.ACT_TXT_PARAM(@P_IDSESSAO, 'CODDEP')
       SET @PARAM_TIPADO = sankhya.ACT_TXT_PARAM(@P_IDSESSAO, 'TIPADO')

       SET @I = 1 -- A variável "I" representa o registro corrente.
       WHILE @I <= @P_QTDLINHAS -- Este loop permite obter o valor de campos dos registros envolvidos na execução.
       BEGIN
           -- Para obter o valor dos campos utilize uma das seguintes funções:
           --     ACT_INT_FIELD (Retorna o valor de um campo tipo NUMÉRICO INTEIRO))
           --     ACT_DEC_FIELD (Retorna o valor de um campo tipo NUMÉRICO DECIMAL))
           --     ACT_TXT_FIELD (Retorna o valor de um campo tipo TEXTO),
           --     ACT_DTA_FIELD (Retorna o valor de um campo tipo DATA)
           -- Estas funções recebem 3 argumentos:
           --     ID DA SESSÃO - Identificador da execução (Obtido através do parâmetro P_IDSESSAO))
           --     NÚMERO DA LINHA - Relativo a qual linha selecionada.
           --     NOME DO CAMPO - Determina qual campo deve ser obtido.
           SET @FIELD_CODEMP = sankhya.ACT_INT_FIELD(@P_IDSESSAO, @I, 'CODEMP')
           SET @FIELD_CODFUNC = sankhya.ACT_INT_FIELD(@P_IDSESSAO, @I, 'CODFUNC')
           SET @FIELD_CODLINHA = sankhya.ACT_INT_FIELD(@P_IDSESSAO, @I, 'CODLINHA')
           SET @FIELD_REFERENCIA = sankhya.ACT_DTA_FIELD(@P_IDSESSAO, @I, 'REFERENCIA')



-- <ESCREVA SEU CÓDIGO AQUI (SERÁ EXECUTADO PARA CADA REGISTRO SELECIONADO)> --



           SET @I = @I + 1
       END

	   SELECT
	   @PARAM_REFORIG = MAX(REFERENCIA)
	   FROM TFPVAL;




        insert into TFPVAL(
        REFERENCIA,
        CODLINHA,
        CODFUNC,
        CODEMP,
        PASSESDIA,
        QTDDIAS,
        DTALTER,
        TIPO,
        VALOR,
        MANTEMPROXIMAREF,
		AD_NUMCARD,
		AD_DHLANC,
		AD_DHALTER,
		AD_CODUSULANC,
		AD_CODUSUALTER
        )
        SELECT
        @PARAM_REFDEST AS REFERENCIA, --VARIAVEL
        VL.CODLINHA,
        VL.CODFUNC,
        VL.CODEMP,
        VL.PASSESDIA,
        0 AS QTDDIAS, 
        GETDATE() AS DTALTER,
        ISNULL((SELECT LI.TIPO FROM TFPLIN LI WHERE LI.CODLINHA = VL.CODLINHA),'T') AS TIPO,
        ISNULL((SELECT LI.VLRTARIFA FROM TFPLIN LI WHERE LI.CODLINHA = VL.CODLINHA),VL.VALOR) AS VALOR,
        'N' AS MANTEMPROXIMAREF,
		VL.AD_NUMCARD,
		getdate(),
		getdate(),
		sankhya.STP_GET_CODUSULOGADO(),
		sankhya.STP_GET_CODUSULOGADO()
        FROM TFPVAL VL
		INNER JOIN TFPFUN FUN ON FUN.CODFUNC = VL.CODFUNC AND FUN.CODEMP = VL.CODEMP
        WHERE CAST(CAST(VL.REFERENCIA AS DATE) AS DATETIME) = CAST(CAST(@PARAM_REFORIG AS DATE) AS DATETIME)
		and (FUN.CODDEP = @PARAM_CODDEP OR @PARAM_CODDEP IS NULL)
        and (VL.TIPO = @PARAM_TIPADO OR ISNULL(@PARAM_TIPADO,'G') = 'G')
		and not exists (SELECT 1 FROM TFPVAL VL2 WHERE VL2.REFERENCIA = @PARAM_REFDEST AND VL2.CODLINHA = VL.CODLINHA AND VL2.CODFUNC = VL.CODFUNC AND VL2.CODEMP = VL.CODEMP);


		/*INSERT INTO AD_CTRBEN (SEQUENCIA, REFERENCIA)
		SELECT
		ISNULL((SELECT MAX(SEQUENCIA) FROM AD_CTRBEN),0)+1
		,@PARAM_REFDEST
		FROM DUAL;*/

		update TFPVAL
		set AD_CONTROLADO = ISNULL(AD_CONTROLADO,0)+1
		WHERE REFERENCIA = @PARAM_REFDEST;
        
        --variaveis:
        --QTDDIAS
        --REFERENCIA ORIGEM
        --REFERENCIA DESTINO


        SET @P_MENSAGEM = 'Registros Cálculados !';



END
