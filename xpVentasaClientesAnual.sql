/*Ventas año por cliente*/
SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF;
--EXEC xpVentasaClientesAnual
IF EXISTS (SELECT 1 FROM Sys.procedures WHERE name = 'xpVentasaClientesAnual')
DROP PROCEDURE xpVentasaClientesAnual
GO
CREATE PROCEDURE xpVentasaClientesAnual
AS
BEGIN
DECLARE
@Ejercicio	int =	YEAR(GETDATE())


DECLARE		@Ventas		TABLE	(
			Cliente		varchar(10),
			Nombre		varchar(100),
			Ventas		float,
			TFActuras		float,
			Factor			float

)

DECLARE		@Pedidos	TABLE (
			Cliente		varchar(10),
			Pedidos		float
)


SET @Ejercicio = (@Ejercicio-1)

INSERT INTO @Ventas

SELECT v.Cliente,
		v.NombreCliente,
		(SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)) AS VentaAnual,
		COUNT(DISTINCT v.MovID) FactAnual,
		((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)) / (COUNT(DISTINCT v.MovID))) AS Factor
 FROM nvk_vw_VentasNetas_Detalle_Cliente	v
WHERE v.Estatus IN ('CONCLUIDO')
	  AND v.Mov NOT IN ('Factura Activo Fijo')
  AND YEAR(v.FechaEmision) = @Ejercicio
GROUP BY v.Cliente,v.NombreCliente
ORDER BY Factor ASC


INSERT INTO @Pedidos

SELECT Cliente,
		COUNT(MovID)
  FROM Venta		v
  JOIN MovTipo		mt		ON Modulo ='VTAS' AND v.Mov=mt.Mov
 WHERE Estatus = 'CONCLUIDO'
   AND v.Mov <> 'Cotizacion'
   AND YEAR(v.FechaEmision) = 2025
   and Clave = 'VTAS.P' 
   and SubClave = 'VTAS.PNVK'
  GROUP BY v.Cliente
 ORDER BY v.Cliente

SELECT a.Cliente+' - '+Nombre AS NombreClinte,
		Ventas,
		TFActuras AS TotalFacturacion,
		Factor
  FROM @Ventas			a
  LEFT JOIN @Pedidos			b		ON a.Cliente=b.Cliente
  ORDER BY Factor ASC
RETURN
END
--select * from MovTipo where Modulo ='VTAS' and Clave = 'VTAS.P' and SubClave = 'VTAS.PNVK'

--select distinct (mov) from nvk_vw_IngresosNetos_Detalle