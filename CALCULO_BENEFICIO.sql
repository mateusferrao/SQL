USE [SANKHYA_PROD]
GO
/****** Object:  StoredProcedure [sankhya].[EVE_AD_CALCULAR_TFPVAL2]    Script Date: 11/10/2024 14:53:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* Runtime-info
Application: CadastroTelasAdicionais
Referer: https://skw.institutodds.org/mge/CadastroTelasAdicionais.xhtml5
ResourceID: br.com.sankhya.core.cfg.DicionarioDados
service-name: AcaoProgramadaSP.createStoredProcedure
uri: /mge/service.sbr
*/
ALTER PROCEDURE [sankhya].[EVE_AD_CALCULAR_TFPVAL2] (
       @P_CODUSU INT,                -- Código do usuário logado
       @P_IDSESSAO VARCHAR(4000),    -- Identificador da execução. Serve para buscar informações dos parâmetros/campos da execução.
       @P_QTDLINHAS INT,             -- Informa a quantidade de registros selecionados no momento da execução.
       @P_MENSAGEM VARCHAR(4000) OUT -- Caso seja passada uma mensagem aqui, ela será exibida como uma informação ao usuário.
) AS
DECLARE
       @PARAM_REFERENCIA DATETIME,
	   @PARAM_REFORIG DATETIME,
       @PARAM_CODEMP VARCHAR(4000),
       @PARAM_CODDEP VARCHAR(4000),
       @FIELD_CODEMP INT,
       @FIELD_CODFUNC INT,
       @FIELD_CODLINHA INT,
       @FIELD_REFERENCIA DATETIME,
       @I INT,
	   @V_CONT_ERRO INT,
	   @V_CONT_ERRO2 INT,
	   @V_SIMNAO VARCHAR(4000),
	   @V_MSGERRADO VARCHAR(4000),
	   @V_ENTROIF INT = 0,
	   @V_VA VARCHAR(5),
	   @V_VT VARCHAR(5),
	   @V_SEQUENCIA INT

BEGIN

       -- Os valores informados pelo formulário de parâmetros, podem ser obtidos com as funções:
       --     ACT_INT_PARAM
       --     ACT_DEC_PARAM
       --     ACT_TXT_PARAM
       --     ACT_DTA_PARAM
       -- Estas funções recebem 2 argumentos:
       --     ID DA SESSÃO - Identificador da execução (Obtido através de P_IDSESSAO))
       --     NOME DO PARAMETRO - Determina qual parametro deve se deseja obter.

       SET @PARAM_REFERENCIA = sankhya.ACT_DTA_PARAM(@P_IDSESSAO, 'REFERENCIA')
       SET @PARAM_CODEMP = sankhya.ACT_TXT_PARAM(@P_IDSESSAO, 'CODEMP')
       SET @PARAM_CODDEP = sankhya.ACT_TXT_PARAM(@P_IDSESSAO, 'CODDEP')

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

           SET @I = @I + 1
       END

	   SELECT
	   @PARAM_REFORIG = MAX(REFERENCIA)
	   FROM TFPVAL;

	   SET @PARAM_REFERENCIA = DATEADD(MONTH, DATEDIFF(MONTH, 0, @PARAM_REFERENCIA), 0);

-->GERAÇÃO DE MOVIMENTO
/*
CODEMP-
CODFUNC-
CODLINHA-
REFERENCIA-
QTDDIAS-
VALOR
VLRTOT
PASSESDIA
FALTAS
OCORRENCIAS
CODUSU
DHINC
FECHADO
CODDEP
*/
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
		AD_CODUSUALTER,
		AD_CONTROLADO
        )
        SELECT
        @PARAM_REFERENCIA AS REFERENCIA, --VARIAVEL
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
		sankhya.STP_GET_CODUSULOGADO(),
		99
        FROM TFPVAL VL
		INNER JOIN TFPFUN FUN ON FUN.CODFUNC = VL.CODFUNC AND FUN.CODEMP = VL.CODEMP
        WHERE CAST(CAST(VL.REFERENCIA AS DATE) AS DATETIME) = (SELECT MAX((CAST(CAST(VL2.REFERENCIA AS DATE) AS DATETIME))) FROM TFPVAL VL2 WHERE VL2.CODEMP = VL.CODEMP AND VL2.CODFUNC = VL.CODFUNC AND VL2.CODLINHA = VL.CODLINHA)
		and (FUN.CODDEP = @PARAM_CODDEP OR @PARAM_CODDEP IS NULL)
        --and (VL.TIPO = @PARAM_TIPADO OR ISNULL(@PARAM_TIPADO,'G') = 'G')
		and not exists (SELECT 1 FROM TFPVAL VL2 WHERE VL2.REFERENCIA = @PARAM_REFERENCIA AND VL2.CODLINHA = VL.CODLINHA AND VL2.CODFUNC = VL.CODFUNC AND VL2.CODEMP = VL.CODEMP);

-->GERAÇÃO DE MOVIMENTO

	   SELECT
		@V_CONT_ERRO = COUNT(*)
	   FROM AD_TFPVALMOV
	   WHERE REFERENCIA = @PARAM_REFERENCIA
	   AND (CODEMP = @PARAM_CODEMP OR @PARAM_CODEMP IS NULL)
	   AND ( (SELECT F.CODDEP FROM TFPFUN F WHERE F.CODEMP = AD_TFPVALMOV.CODEMP AND F.CODFUNC = AD_TFPVALMOV.CODFUNC) = @PARAM_CODDEP OR @PARAM_CODDEP IS NULL)
	   AND ISNULL(FECHADO,0) <> 1;

      SET @V_SIMNAO = 'N';
	  IF @V_CONT_ERRO > 0
	   BEGIN
	    SET @V_MSGERRADO = CONCAT('Referência <b>',FORMAT(@PARAM_REFERENCIA,'dd/MM/yyyy') ,'</b> já se encontra calculada na tela de Movimento Benefícios !')
		SET @V_SIMNAO = SANKHYA.ACT_ESCOLHER_SIMNAO('Deseja Recalcular a Referência ?', @V_MSGERRADO, @P_IDSESSAO, @I);
		SET @V_ENTROIF = 1;
	   END


IF (@V_ENTROIF = 1 AND @V_SIMNAO = 'S') OR @V_ENTROIF = 0
BEGIN

	   SELECT
		@V_CONT_ERRO2 = COUNT(*)
	   FROM AD_TFPVALMOV
	   WHERE REFERENCIA = @PARAM_REFERENCIA
	   AND (CODEMP = @PARAM_CODEMP OR @PARAM_CODEMP IS NULL)
	   AND ( (SELECT F.CODDEP FROM TFPFUN F WHERE F.CODEMP = AD_TFPVALMOV.CODEMP AND F.CODFUNC = AD_TFPVALMOV.CODFUNC) = @PARAM_CODDEP OR @PARAM_CODDEP IS NULL)
	   AND ISNULL(FECHADO,0) = 1;

	  IF @V_CONT_ERRO2 > 0
	   BEGIN
	    SET @V_MSGERRADO = CONCAT('Referência ',FORMAT(@PARAM_REFERENCIA,'dd/MM/yyyy') ,' já se encontra Fechada !')
		RAISERROR(@V_MSGERRADO , 16, 1 );
	   END



/*	   
	   INSERT INTO AD_TFPVALMOV
	   (CODEMP,CODFUNC,CODLINHA,REFERENCIA,QTDDIAS,VALOR,VLRTOT,PASSESDIA,FALTAS,OCORRENCIAS,CODUSU,DHINC,CODDEP)
	   SELECT
	   CODEMP,CODFUNC,CODLINHA,REFERENCIA,QTDDIAS,VALOR
	   ,((isnull(TFPVAL.QTDDIAS,0)-((ISNULL(sankhya.AD_BEN_FALTA (TFPVAL.CODEMP, TFPVAL.CODFUNC, TFPVAL.REFERENCIA),0)*ISNULL(TFPVAL.AD_FIXADO,1))+(ISNULL(sankhya.AD_BEN_OCORRE_ATUAL (TFPVAL.CODEMP, TFPVAL.CODFUNC, TFPVAL.REFERENCIA),0)*ISNULL(TFPVAL.AD_FIXADO,1))+(ISNULL(sankhya.AD_BEN_OCORRE_ANTERIOR (TFPVAL.CODEMP, TFPVAL.CODFUNC, TFPVAL.REFERENCIA),0)*ISNULL(TFPVAL.AD_FIXADO,1))))
		*
		(TFPVAL.PASSESDIA)
		*
		(TFPVAL.VALOR)) VLRTOT
	   ,PASSESDIA
	   ,(ISNULL(sankhya.AD_BEN_FALTA (TFPVAL.CODEMP, TFPVAL.CODFUNC, TFPVAL.REFERENCIA),0)) FALTAS
	   ,((ISNULL(sankhya.AD_BEN_OCORRE_ATUAL (TFPVAL.CODEMP, TFPVAL.CODFUNC, TFPVAL.REFERENCIA),0))+(ISNULL(sankhya.AD_BEN_OCORRE_ANTERIOR (TFPVAL.CODEMP, TFPVAL.CODFUNC, TFPVAL.REFERENCIA),0))) OCORRENCIAS
	   ,SANKHYA.STP_GET_CODUSULOGADO()
	   ,GETDATE()
	   ,(SELECT F.CODDEP FROM TFPFUN F WHERE F.CODEMP = TFPVAL.CODEMP AND F.CODFUNC = TFPVAL.CODFUNC) CODDEP
	   FROM TFPVAL
 	   WHERE REFERENCIA = @PARAM_REFERENCIA
	   AND (CODEMP = @PARAM_CODEMP OR @PARAM_CODEMP IS NULL)
	   AND ( (SELECT F.CODDEP FROM TFPFUN F WHERE F.CODEMP = TFPVAL.CODEMP AND F.CODFUNC = TFPVAL.CODFUNC) = @PARAM_CODDEP OR @PARAM_CODDEP IS NULL);
*/

	   UPDATE TFPVAL
	   SET AD_GERADO = 1
	   ,QTDDIAS = AD_QTDDIAS2
	   WHERE REFERENCIA = @PARAM_REFERENCIA
	   AND (CODEMP = @PARAM_CODEMP OR @PARAM_CODEMP IS NULL)
	   AND ( (SELECT F.CODDEP FROM TFPFUN F WHERE F.CODEMP = TFPVAL.CODEMP AND F.CODFUNC = TFPVAL.CODFUNC) = @PARAM_CODDEP OR @PARAM_CODDEP IS NULL);

	   DELETE FROM AD_TFPVALMOV
	   WHERE REFERENCIA = @PARAM_REFERENCIA
	   AND (CODEMP = @PARAM_CODEMP OR @PARAM_CODEMP IS NULL)
	   AND ( (SELECT F.CODDEP FROM TFPFUN F WHERE F.CODEMP = AD_TFPVALMOV.CODEMP AND F.CODFUNC = AD_TFPVALMOV.CODFUNC) = @PARAM_CODDEP OR @PARAM_CODDEP IS NULL)
	   AND ISNULL(FECHADO,0) <> 1;

--> CURSOR PARA GERAÇÃO DOS CALCULOS
		DECLARE @CODEMP INT, @CODFUNC INT, @CODLINHA INT, @REFERENCIA DATETIME, 
				@QTDDIAS INT, @VALOR DECIMAL(18, 2), @VLRTOT DECIMAL(18, 2), 
				@PASSESDIA INT, @FALTAS INT, @OCORRENCIAS INT, @CODUSU INT, 
				@DHINC DATETIME, @CODDEP INT, @TIPO VARCHAR(50),@AD_FIXADO INT;

		DECLARE cursor_TFPVAL CURSOR FOR
		SELECT 
			CODEMP, CODFUNC, CODLINHA, REFERENCIA, QTDDIAS, VALOR,
			((ISNULL(TFPVAL.QTDDIAS, 0) - 
			((ISNULL(sankhya.AD_BEN_FALTA(TFPVAL.CODEMP, TFPVAL.CODFUNC, TFPVAL.REFERENCIA), 0) * ISNULL(TFPVAL.AD_FIXADO, 1)) + 
			(ISNULL(sankhya.AD_BEN_OCORRE_ATUAL(TFPVAL.CODEMP, TFPVAL.CODFUNC, TFPVAL.REFERENCIA), 0) * ISNULL(TFPVAL.AD_FIXADO, 1)) + 
			(ISNULL(sankhya.AD_BEN_OCORRE_ANTERIOR(TFPVAL.CODEMP, TFPVAL.CODFUNC, TFPVAL.REFERENCIA), 0) * ISNULL(TFPVAL.AD_FIXADO, 1)))) *
			(TFPVAL.PASSESDIA) * 
			(TFPVAL.VALOR)) AS VLRTOT,
			PASSESDIA,
			(ISNULL(sankhya.AD_BEN_FALTA(TFPVAL.CODEMP, TFPVAL.CODFUNC, TFPVAL.REFERENCIA), 0)) AS FALTAS,
			((ISNULL(sankhya.AD_BEN_OCORRE_ATUAL(TFPVAL.CODEMP, TFPVAL.CODFUNC, TFPVAL.REFERENCIA), 0)) + 
			(ISNULL(sankhya.AD_BEN_OCORRE_ANTERIOR(TFPVAL.CODEMP, TFPVAL.CODFUNC, TFPVAL.REFERENCIA), 0))) AS OCORRENCIAS,
			TFPVAL.TIPO,
			TFPVAL.AD_FIXADO
		FROM 
			TFPVAL
		WHERE 
			REFERENCIA = @PARAM_REFERENCIA
			AND (CODEMP = @PARAM_CODEMP OR @PARAM_CODEMP IS NULL)
			AND ((SELECT F.CODDEP FROM TFPFUN F WHERE F.CODEMP = TFPVAL.CODEMP AND F.CODFUNC = TFPVAL.CODFUNC) = @PARAM_CODDEP OR @PARAM_CODDEP IS NULL);

		OPEN cursor_TFPVAL;

		FETCH NEXT FROM cursor_TFPVAL INTO 
			@CODEMP, @CODFUNC, @CODLINHA, @REFERENCIA, @QTDDIAS, @VALOR, @VLRTOT, 
			@PASSESDIA, @FALTAS, @OCORRENCIAS, @TIPO,@AD_FIXADO;

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @CODUSU = SANKHYA.STP_GET_CODUSULOGADO();
			SET @DHINC = GETDATE();
			SET @CODDEP = (SELECT F.CODDEP FROM TFPFUN F WHERE F.CODEMP = @CODEMP AND F.CODFUNC = @CODFUNC);

			DELETE FROM AD_TFPVALMOV WHERE REFERENCIA = @REFERENCIA AND CODLINHA = @CODLINHA AND CODEMP = @CODEMP AND CODFUNC = @CODFUNC AND ISNULL(FECHADO,0) <> 1;

			INSERT INTO AD_TFPVALMOV
			(CODEMP, CODFUNC, CODLINHA, REFERENCIA, QTDDIAS, VALOR, VLRTOT, PASSESDIA, FALTAS, OCORRENCIAS, CODUSU, DHINC, CODDEP,TIPO,AD_FIXADO)
			VALUES
			(@CODEMP, @CODFUNC, @CODLINHA, @REFERENCIA, @QTDDIAS, @VALOR, @VLRTOT, 
			@PASSESDIA, @FALTAS, @OCORRENCIAS, @CODUSU, @DHINC, @CODDEP,@TIPO,@AD_FIXADO);

			SELECT
			@V_VA = ISNULL(F.AD_OPTVA,'N')
			,@V_VT = ISNULL(F.AD_OPTVT,'N')
			FROM TFPFUN F
			WHERE F.CODEMP = @CODEMP
			AND F.CODFUNC = @CODFUNC;

			IF @TIPO ='T' AND @V_VT = 'N'
			BEGIN
				SELECT
				@V_SEQUENCIA = ISNULL(MAX(SEQUENCIA),0)+1
				FROM AD_TFPVALLOG
				WHERE REFERENCIA = @REFERENCIA
				AND CODEMP = @CODEMP
				AND CODFUNC = @CODFUNC;

				INSERT INTO AD_TFPVALLOG
				(SEQUENCIA, CODEMP, CODFUNC, REFERENCIA, OPTVA, OPTVR, AVISO, OBSERVACAO, CODDEP)
				VALUES
				(@V_SEQUENCIA, @CODEMP, @CODFUNC, @REFERENCIA, @V_VA,@V_VT,'E','Funcionário com opção "Optante Vale Transporte" Desmarcada',@CODDEP );
			END

			IF @TIPO ='A' AND @V_VA = 'N'
			BEGIN
				SELECT
				@V_SEQUENCIA = ISNULL(MAX(SEQUENCIA),0)+1
				FROM AD_TFPVALLOG
				WHERE REFERENCIA = @REFERENCIA
				AND CODEMP = @CODEMP
				AND CODFUNC = @CODFUNC;

				INSERT INTO AD_TFPVALLOG
				(SEQUENCIA, CODEMP, CODFUNC, REFERENCIA, OPTVA, OPTVR, AVISO, OBSERVACAO, CODDEP)
				VALUES
				(@V_SEQUENCIA, @CODEMP, @CODFUNC, @REFERENCIA, @V_VA,@V_VT,'E','Funcionário com opção "Optante Vale Alimentação" Desmarcada',@CODDEP );
			END
			
			DELETE FROM TFPVAL WHERE REFERENCIA = @REFERENCIA AND CODLINHA = @CODLINHA AND CODEMP = @CODEMP AND CODFUNC = @CODFUNC;

			FETCH NEXT FROM cursor_TFPVAL INTO 
				@CODEMP, @CODFUNC, @CODLINHA, @REFERENCIA, @QTDDIAS, @VALOR, @VLRTOT, 
				@PASSESDIA, @FALTAS, @OCORRENCIAS,@TIPO,@AD_FIXADO;
		END

		CLOSE cursor_TFPVAL;
		DEALLOCATE cursor_TFPVAL;

	    SET @P_MENSAGEM = 'Cálculo realizado !';

END
END
