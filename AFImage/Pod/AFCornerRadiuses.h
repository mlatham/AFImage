
typedef struct
{
	CGFloat topLeft;
	CGFloat topRight;
	CGFloat bottomLeft;
	CGFloat bottomRight;
	
} AFCornerRadiuses;

static inline AFCornerRadiuses AFCornerRadiusesMake(CGFloat topLeft, CGFloat topRight, CGFloat bottomLeft, CGFloat bottomRight)
{
	AFCornerRadiuses radiuses;
	
	radiuses.topLeft = topLeft;
	radiuses.topRight = topRight;
	radiuses.bottomLeft = bottomLeft;
	radiuses.bottomRight = bottomRight;
	
	return radiuses;
}