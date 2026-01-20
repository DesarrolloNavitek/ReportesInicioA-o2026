
/*Ventas año por cliente*/
SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF;
--EXEC xpVentasCuota
IF EXISTS (SELECT 1 FROM Sys.procedures WHERE name = 'xpVentasCuota')
DROP PROCEDURE xpVentasCuota
GO
CREATE PROCEDURE xpVentasCuota
AS
BEGIN
DECLARE	@EjercicioD		int = YEAR(GETDATE()),
		@EjercicioA		int = NULL, 
		@Ejercicio1	int = NULL, 
		@Ejercicio2	int = NULL, 
		@Ejercicio3	int = NULL, 
		@Ejercicio4	int = NULL, 
		@Ejercicio5	int = NULL

		DELETE FROM nvk_tb_ExpIngresoNeto_Imp WHERE SPID = @@SPID

DECLARE @VentasBase TABLE (
					Cliente			varchar(10) ,
					Nombre			varchar(100),
					Ejercicio		int,
					VentaNeta		float,
					Agente			varchar(10),
					NombreAgente	varchar(100),
					Gerente			varchar(10)
					)


DECLARE @MaxMin		TABLE (
					Cliente		varchar(10),
					vMax		float NULL,
					vMin		float NULL
)



SET @EjercicioA = (@EjercicioD-1)
SET @EjercicioD = (@EjercicioD-5)



SET @Ejercicio1 = (@EjercicioA-4)
SET @Ejercicio2 = (@EjercicioA-3)
SET @Ejercicio3 = (@EjercicioA-2)
SET @Ejercicio4 = (@EjercicioA-1)
SET @Ejercicio5 = @EjercicioA

INSERT INTO @VentasBase

SELECT 
DISTINCT V.Cliente
	,NombreCliente
	,YEAR(FechaEmision) AS Ejercicio
	--,CASE WHEN YEAR(FechaEmision) = 2021 THEN COALESCE((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)),0)  ELSE 0 END AS VTotalEjercicio1
	--,CASE WHEN YEAR(FechaEmision) = 2022 THEN COALESCE((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)),0)  ELSE 0 END AS VTotalEjercicio2
	--,CASE WHEN YEAR(FechaEmision) = 2023 THEN COALESCE((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)),0)  ELSE 0 END AS VTotalEjercicio3
	--,CASE WHEN YEAR(FechaEmision) = 2024 THEN COALESCE((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)),0)  ELSE 0 END AS VTotalEjercicio4
	--,CASE WHEN YEAR(FechaEmision) = 2025 THEN COALESCE((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)),0)  ELSE 0 END AS VTotalEjercicio5
	
	
	,CASE WHEN YEAR(FechaEmision) = @Ejercicio1  THEN (SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred))
	      WHEN YEAR(FechaEmision) = @Ejercicio2 THEN (SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred))
			WHEN YEAR(FechaEmision) = @Ejercicio3 THEN (SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred))
			WHEN YEAR(FechaEmision) = @Ejercicio4 THEN (SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred))
			WHEN YEAR(FechaEmision) = @Ejercicio5 THEN (SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred))
			ELSE 0 END AS VentaNeta,
	v.AgenteCliente,
	a.Nombre,
	MAX(CASE WHEN COALESCE(a.ReportaA,'') = '' THEN a.Agente ELSE a.ReportaA END)
   FROM  NVK_VW_HistVtaCte_2021_Hoy v
   LEFT JOIN Agente	a							ON a.Agente=v.AgenteCliente
   LEFT JOIN Cte b								ON v.Cliente=b.cliente AND b.Estatus = 'ALTA'
   WHERE v.Mov NOT IN ('Factura Activo Fijo')
	 AND YEAR(FechaEmision) BETWEEN @EjercicioD AND @EjercicioA
	 AND v.Estatus = 'CONCLUIDO'
      GROUP BY YEAR(FechaEmision),v.Cliente,v.NombreCliente,v.AgenteCliente,a.ReportaA,a.Nombre



INSERT INTO @MaxMin

SELECT Cliente, MAX(VentaNeta),MIN(VentaNeta) 
  FROM @VentasBase
 GROUP BY Cliente



   SELECT
   Gerente,
   d.Nombre					AS NombreGerente,
   a.Agente					AS Agente,
   a.NombreAgente			AS NombreAgente,
   a.Cliente,
   a.Nombre			AS NombreCliente,
    ROUND(COALESCE(MAX(CASE WHEN Ejercicio = @Ejercicio1 THEN VentaNeta END),0),4) AS '2021',
    ROUND(COALESCE(MAX(CASE WHEN Ejercicio = @Ejercicio2 THEN VentaNeta END),0),4) AS '2022',
    ROUND(COALESCE(MAX(CASE WHEN Ejercicio = @Ejercicio3 THEN VentaNeta END),0),4) AS '2023',
	ROUND(COALESCE(MAX(CASE WHEN Ejercicio = @Ejercicio4 THEN VentaNeta END),0),4) AS '2024',
	ROUND(COALESCE(MAX(CASE WHEN Ejercicio = @Ejercicio5 THEN VentaNeta END),0),4) AS '2025',
	CASE WHEN vMin = vMax THEN 0.00 ELSE vMin END	AS VentaMenor,
	vMax			AS VentaMayor,
	Cuota= ''
FROM @VentasBase						a
JOIN @MaxMin							c		ON		c.Cliente=a.Cliente
JOIN Agente								d		ON		d.Agente=a.Gerente

GROUP BY a.Cliente,a.Nombre,d.Agente,a.NombreAgente,D.ReportaA,Gerente,/*e.Nombre,*/a.Agente,d.Nombre,vMin,vMax
ORDER BY a.Cliente

RETURN

END

