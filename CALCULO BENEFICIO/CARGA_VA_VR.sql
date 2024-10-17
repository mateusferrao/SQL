/* Runtime-info
Application: CadastroTelasAdicionais
Referer: https://skw.institutodds.org/mge/CadastroTelasAdicionais.xhtml5
ResourceID: br.com.sankhya.core.cfg.DicionarioDados
service-name: AcaoProgramadaSP.createStoredProcedure
uri: /mge/service.sbr
*/
ALTER PROCEDURE [sankhya].[CARGA_INICIAL_VA_VR_CR] (
       @V_CODEMP INT,
	   @V_CODDEP INT,
	   @V_CODLINHA INT,
	   @V_REFERENCIA DATE

) AS
DECLARE
       @FIELD_CODEMP INT,
       @FIELD_CODFUNC INT,
       @FIELD_NOMEFUNC VARCHAR(100),
       @FIELD_CODLINHA INT,
       @FIELD_CODDEP INT,
       @FIELD_PASSESDIA INT,
       @FIELD_REFERENCIA DATETIME,
       @V_TIPO CHAR(1),
       @V_VALOR FLOAT,
       @I INT,
       @FIELD_AD_OPTVA CHAR(1),
       @FIELD_AD_OPTVT CHAR(1),
	   @FIELD_SITUACAO CHAR(1),
	   @FIELD_DTDEM DATE;

	BEGIN TRY
	  BEGIN TRANSACTION
	   DECLARE CURSOR_FUNCIONARIOS CURSOR LOCAL FOR
	    SELECT 
		CODFUNC,
		NOMEFUNC, 
		ISNULL(AD_OPTVA,'X'),
		ISNULL(AD_OPTVT,'X'),
		SITUACAO,
		ISNULL(DTDEM,'1900-01-01')
		FROM TFPFUN
		WHERE CODDEP = @V_CODDEP
		AND CODEMP = @V_CODEMP;

	
	   OPEN CURSOR_FUNCIONARIOS

	   FETCH NEXT FROM CURSOR_FUNCIONARIOS INTO 
	      @FIELD_CODFUNC,
          @FIELD_NOMEFUNC, 
          @FIELD_AD_OPTVA, 
	      @FIELD_AD_OPTVT,
		  @FIELD_SITUACAO,
		  @FIELD_DTDEM

		  
		PRINT @@FETCH_STATUS
	   WHILE @@FETCH_STATUS = 0
	      BEGIN
				PRINT '#####'
	            PRINT'FUNCIONARIO '+@FIELD_NOMEFUNC
				PRINT'SITUAÇÃO: '+@FIELD_SITUACAO + ' DT. DEMISSAO: '+CAST(@FIELD_DTDEM AS VARCHAR)
				PRINT'OPT. VA '+@FIELD_AD_OPTVA
                PRINT'OPT. VT '+@FIELD_AD_OPTVT

				
		    IF @FIELD_AD_OPTVA = 'X' AND @FIELD_SITUACAO = '1'
				BEGIN
					PRINT'ALTERANDO OPCAO DE VA PARA SIM'
					UPDATE TFPFUN
					SET AD_OPTVA = 'S'
					WHERE CODEMP = @V_CODEMP
					AND CODFUNC = @FIELD_CODFUNC

					SET @FIELD_AD_OPTVA = 'S'
				END
			 IF @FIELD_SITUACAO = '0'
				BEGIN
					PRINT'ALTERANDO OPCAO DE VA PARA NÃO - FUNCIONARIO DEMITIDO'
					UPDATE TFPFUN
					SET AD_OPTVA = 'N'
					WHERE CODEMP = @V_CODEMP
					AND CODFUNC = @FIELD_CODFUNC

				END
					

		    IF @FIELD_AD_OPTVT = 'X' OR @FIELD_SITUACAO = '0'
				BEGIN
					PRINT'ALTERANDO OPCAO DE VT PARA NAO'
					UPDATE TFPFUN
					SET AD_OPTVT = 'N'
					WHERE CODEMP = @V_CODEMP
					AND CODFUNC = @FIELD_CODFUNC
					PRINT '#####'
				END
			 
			 IF @FIELD_AD_OPTVA = 'S' AND @FIELD_SITUACAO = '1'
				BEGIN
						PRINT'VOU INSERIR TFPVAL'
						INSERT INTO TFPVAL
						(
						CODEMP,
						CODFUNC,
						CODLINHA,
						PASSESDIA,
						QTDDIAS,
						AD_QTDDIAS2,
						DTALTER,
						TIPO,
						REFERENCIA,
						MANTEMPROXIMAREF,
						VALOR,
						AD_DHALTER,
						AD_DHLANC,
						AD_CODUSUALTER,
						AD_CODUSULANC
						)
						VALUES 
						(
						@V_CODEMP,
						@FIELD_CODFUNC,
						@V_CODLINHA,
						1,
						1,
						1,
						GETDATE(),
						'A',
						@V_REFERENCIA,
						'N',
						1,
						GETDATE(),
						GETDATE(),
						20994,
						20994
						)

						PRINT'JA INSERI TFPVAL'
					END

						FETCH NEXT FROM CURSOR_FUNCIONARIOS INTO 
						@FIELD_CODFUNC,
						@FIELD_NOMEFUNC, 
						@FIELD_AD_OPTVA, 
						@FIELD_AD_OPTVT,
						@FIELD_SITUACAO,
						@FIELD_DTDEM
					


	      END

            CLOSE CURSOR_FUNCIONARIOS
	    DEALLOCATE CURSOR_FUNCIONARIOS	 

		COMMIT TRANSACTION;

		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			PRINT 'ERRO: ' + ERROR_MESSAGE();
		END CATCH;

		

