
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


DECLARE @VentasBase TABLE (
					Cliente varchar(10) ,
					Nombre	varchar(100),
					Ejercicio int,
					VentaNeta	float,
					Agente varchar(10)
					)


DECLARE @MaxMin		TABLE (
					Cliente varchar(10),
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
	--,CASE WHEN YEAR(FechaEmision) = 2021 THEN COALESCE(ROUND((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)),4),0)  ELSE 0 END AS VTotalEjercicio1
	--,CASE WHEN YEAR(FechaEmision) = 2022 THEN COALESCE(ROUND((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)),4),0)  ELSE 0 END AS VTotalEjercicio2
	--,CASE WHEN YEAR(FechaEmision) = 2023 THEN COALESCE(ROUND((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)),4),0)  ELSE 0 END AS VTotalEjercicio3
	--,CASE WHEN YEAR(FechaEmision) = 2024 THEN COALESCE(ROUND((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)),4),0)  ELSE 0 END AS VTotalEjercicio4
	--,CASE WHEN YEAR(FechaEmision) = 2025 THEN COALESCE(ROUND((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)),4),0)  ELSE 0 END AS VTotalEjercicio5
	
	
	,CASE WHEN YEAR(FechaEmision) = @Ejercicio1  THEN ROUND((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)),4)
	      WHEN YEAR(FechaEmision) = @Ejercicio2 THEN ROUND((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)),4)
			WHEN YEAR(FechaEmision) = @Ejercicio3 THEN ROUND((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)),4)
			WHEN YEAR(FechaEmision) = @Ejercicio4 THEN ROUND((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)),4)
			WHEN YEAR(FechaEmision) = @Ejercicio5 THEN ROUND((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)),4)
			ELSE 0 END AS VentaNeta,
	v.AgenteCliente
   FROM  NVK_VW_HistVtaCte_2021_Hoy v 
   WHERE v.Mov NOT IN ('Factura Activo Fijo')
	 AND YEAR(FechaEmision) BETWEEN @EjercicioD AND @EjercicioA
	 AND v.Estatus = 'CONCLUIDO'
	 --AND Cliente = '00'
      GROUP BY YEAR(FechaEmision),v.Cliente,v.NombreCliente,v.AgenteCliente



INSERT INTO @MaxMin

SELECT Cliente, MAX(VentaNeta),MIN(VentaNeta) 
  FROM @VentasBase
 GROUP BY Cliente



   SELECT 
    a.Cliente+' - '+a.Nombre	AS NombreCliente,
    COALESCE(MAX(CASE WHEN Ejercicio = @Ejercicio1 THEN VentaNeta END),0) AS VentaNetaE1,
    COALESCE(MAX(CASE WHEN Ejercicio = @Ejercicio2 THEN VentaNeta END),0) AS VentaNetaE2,
    COALESCE(MAX(CASE WHEN Ejercicio = @Ejercicio3 THEN VentaNeta END),0) AS VentaNetaE3,
	COALESCE(MAX(CASE WHEN Ejercicio = @Ejercicio4 THEN VentaNeta END),0) AS VentaNetaE4,
	COALESCE(MAX(CASE WHEN Ejercicio = @Ejercicio5 THEN VentaNeta END),0) AS VentaNetaE5,
	CASE WHEN vMin = vMax THEN 0.00 ELSE vMin END	AS VentaMenor,
	vMax	AS VentaMayor,
	a.Agente+' - '+d.Nombre AS NombreAgente

FROM @VentasBase						a
JOIN @MaxMin							c		ON		c.Cliente=a.Cliente
JOIN Agente							d		ON		d.Agente=a.Agente
GROUP BY a.Cliente,a.Nombre,a.Agente,d.Nombre,vMin,vMax
ORDER BY a.Cliente

RETURN
END