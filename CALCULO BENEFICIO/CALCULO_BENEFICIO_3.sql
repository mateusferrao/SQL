USE [SANKHYA_PROD]
GO
/****** Object:  StoredProcedure [sankhya].[EVE_AD_CALCULAR_TFPVAL3]    Script Date: 11/10/2024 15:00:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* Runtime-info
Application: CadastroTelasAdicionais
Referer: https://skw.institutodds.org/mge/flex/CadastroTelasAdicionais.swf/[[DYNAMIC]]/3
ResourceID: br.com.sankhya.core.cfg.TelasPersonalizadas
service-name: AcaoProgramadaSP.createStoredProcedure
uri: /mge/service.sbr
*/
ALTER PROCEDURE [sankhya].[EVE_AD_CALCULAR_TFPVAL3] (
       @P_CODUSU INT,                -- Código do usuário logado
       @P_IDSESSAO VARCHAR(4000),    -- Identificador da execução. Serve para buscar informações dos parâmetros/campos da execução.
       @P_QTDLINHAS INT,             -- Informa a quantidade de registros selecionados no momento da execução.
       @P_MENSAGEM VARCHAR(4000) OUT -- Caso seja passada uma mensagem aqui, ela será exibida como uma informação ao usuário.
) AS
DECLARE
       @PARAM_REFERENCIA DATETIME,
       @PARAM_CODEMP VARCHAR(4000),
       @PARAM_CODDEP VARCHAR(4000),
       @PARAM_CODEMP2 VARCHAR(4000),
       @PARAM_CODDEP2 VARCHAR(4000),
       @FIELD_CODEMP INT,
       @FIELD_CODFUNC INT,
       @FIELD_CODLINHA INT,
       @FIELD_REFERENCIA DATETIME,
       @I INT,
	   @V_SIMNAO VARCHAR(5),
	   @V_MSGERRADO VARCHAR(MAX),
	   @V_MSGERRADO2 VARCHAR(MAX),
	   @V_MSGERRADO3 VARCHAR(MAX),
	   @V_MSGERRADO4 VARCHAR(MAX)

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

	   SET @PARAM_REFERENCIA = DATEADD(MONTH, DATEDIFF(MONTH, 0, @PARAM_REFERENCIA), 0);

	   SELECT
	   @PARAM_CODEMP2 = CONCAT(CODEMP,' - ',RAZAOABREV)
	   FROM TSIEMP
	   WHERE CODEMP = @PARAM_CODEMP;

	   SELECT
	   @PARAM_CODDEP2 = CONCAT(CODDEP,' - ',DESCRDEP)
	   FROM TFPDEP
	   WHERE CODDEP = @PARAM_CODDEP;


	   SET @V_MSGERRADO = CONCAT('Referência: <b>', FORMAT(@PARAM_REFERENCIA,'dd/MM/yyyy') , '</b><br>');
	   SET @V_MSGERRADO2 = CONCAT('Empresa: <b>', ISNULL(@PARAM_CODEMP2,'Todos') , '</b><br>' );
	   SET @V_MSGERRADO3 = CONCAT('Departamento: <b>',ISNULL(@PARAM_CODDEP2,'Todos'));
	   SET @V_MSGERRADO4 = CONCAT(@V_MSGERRADO,@V_MSGERRADO2,@V_MSGERRADO3);

	   SET @V_SIMNAO = SANKHYA.ACT_ESCOLHER_SIMNAO('Deseja realmente fechar a Referência ?', @V_MSGERRADO4, @P_IDSESSAO, @I);

	   IF @V_SIMNAO = 'S'
	   BEGIN
		UPDATE AD_TFPVALMOV
		SET FECHADO = 1
		WHERE REFERENCIA = @PARAM_REFERENCIA
		AND (CODEMP = @PARAM_CODEMP OR @PARAM_CODEMP IS NULL)
		AND (CODDEP = @PARAM_CODDEP OR @PARAM_CODDEP IS NULL);

	   SET @P_MENSAGEM = 'Referência Fechada !';

	END
END
